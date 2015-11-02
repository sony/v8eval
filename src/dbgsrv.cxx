#include "dbgsrv.h"
#include "v8eval.h"

namespace v8eval {

//
// DbgSrv
//

// container_of helper function
//
// libuv does not accept opaque values in its callbacks, so we have to
// recover the instance of the debug server (and associated v8 vm)
// through a C++ version of offsetof().
template<class A, class B, class C>
A* container_of(B* ptr, const C A::* member) {
  size_t offset = (size_t) &(reinterpret_cast<A*>(0)->*member);
  return (A*)((char *)ptr - offset);
}

DbgSrv::DbgSrv(_V8& v8) : v8_(v8) {
  dbgsrv_port_ = 0;
  uv_loop_init(&dbgsrv_loop_);

  // Start up the Debugger Processing Loop
  uv_loop_init(&dbgproc_loop_);
  uv_async_init(&dbgproc_loop_, &dbgproc_proc_, dbgproc_do_proc);
  uv_async_init(&dbgproc_loop_, &dbgproc_stop_, dbgproc_do_stop);
  uv_thread_create(&dbgproc_thread_, dbgproc, this);

  status_ = dbgsrv_offline;
}

DbgSrv::~DbgSrv() {
  if (status_ != dbgsrv_offline) {
    v8_.debugger_stop();
    uv_async_send(&dbgsrv_stop_);
    uv_thread_join(&dbgsrv_thread_);
  }
  uv_loop_close(&dbgsrv_loop_);

  uv_async_send(&dbgproc_stop_);
  uv_thread_join(&dbgproc_thread_);
  uv_loop_close(&dbgproc_loop_);
}

static void end_write(uv_write_t *req, int status) {
  if (status) {
    fprintf(stderr, "write: %s\n", uv_strerror(status));
  }
  free(req);
}

void DbgSrv::dbgsrv_do_send(uv_async_t *async) {
  DbgSrv *db = container_of(async, &DbgSrv::dbgsrv_send_);
  uv_buf_t buf;
  uv_write_t *wreq;

  while (!db->msg_queue_.empty()) {
    std::string& str = db->msg_queue_.back();

    buf = uv_buf_init((char *)str.c_str(), (unsigned int)str.size());
    wreq = (uv_write_t *)malloc(sizeof(*wreq));
    uv_write(wreq, (uv_stream_t *)&db->dbgsrv_clnt_, &buf, 1, end_write);
    db->msg_queue_.pop_back();
  }
}

void DbgSrv::dbgsrv_do_clnt(uv_stream_t *client, ssize_t nread, const uv_buf_t *buf) {
  DbgSrv *db = container_of(client, &DbgSrv::dbgsrv_clnt_);

  if (nread == 0) return;

  if (nread < 0) {
    // Close the client
    uv_close((uv_handle_t *)&db->dbgsrv_send_, NULL);
    uv_close((uv_handle_t *)&db->dbgsrv_clnt_, NULL);
    db->status_ = dbgsrv_started;
    return;
  }

  const std::string string(buf->base, nread);
  db->v8_.debugger_send(string);
  free(buf->base);

  uv_async_send(&db->dbgproc_proc_);
}

static void alloc_buffer(uv_handle_t *handle, size_t size, uv_buf_t *buf) {
  buf->len = size;
  buf->base = (char*) malloc(size);
}

void DbgSrv::dbgsrv_do_serv(uv_stream_t *server, int status) {
  DbgSrv *db = container_of(server, &DbgSrv::dbgsrv_serv_);

  if (status < 0) {
    return;
  }

  // Connect with the client.
  uv_tcp_init(&db->dbgsrv_loop_, &db->dbgsrv_clnt_);
  if (uv_accept(server, (uv_stream_t *)&db->dbgsrv_clnt_)) {
    uv_close((uv_handle_t *)&db->dbgsrv_clnt_, NULL);
    return;
  }

  // Setup async R/W callbacks.
  uv_async_init(&db->dbgsrv_loop_, &db->dbgsrv_send_, dbgsrv_do_send);
  uv_read_start((uv_stream_t *)&db->dbgsrv_clnt_, alloc_buffer, dbgsrv_do_clnt);

  db->status_ = dbgsrv_connected;
}

void DbgSrv::dbgsrv_do_stop(uv_async_t *async) {
  DbgSrv *db = container_of(async, &DbgSrv::dbgsrv_stop_);

  // Stop Server Loop
  if (db->status_ == dbgsrv_connected) {
    uv_close((uv_handle_t *)&db->dbgsrv_send_, NULL);
    uv_close((uv_handle_t *)&db->dbgsrv_clnt_, NULL);
    db->status_ = dbgsrv_started;
  }
  if (db->status_ == dbgsrv_started) {
    uv_close((uv_handle_t *)&db->dbgsrv_serv_, NULL);
    uv_close((uv_handle_t *)&db->dbgsrv_stop_, NULL);
  }
}

void DbgSrv::dbgsrv(void *ptr) {
  DbgSrv *db = (DbgSrv*)ptr;

  uv_run(&db->dbgsrv_loop_, UV_RUN_DEFAULT);
}

void DbgSrv::dbgproc_do_stop(uv_async_t *async) {
  DbgSrv *db = container_of(async, &DbgSrv::dbgproc_stop_);

  uv_close((uv_handle_t *)&db->dbgproc_proc_, NULL);
  uv_close((uv_handle_t *)&db->dbgproc_stop_, NULL);
}

void DbgSrv::dbgproc_do_proc(uv_async_t *async) {
  DbgSrv *db = container_of(async, &DbgSrv::dbgproc_proc_);

  db->v8_.debugger_process();
}

void DbgSrv::dbgproc(void *ptr) {
  DbgSrv *db = (DbgSrv*)ptr;

  uv_run(&db->dbgproc_loop_, UV_RUN_DEFAULT);
}

void DbgSrv::recv_from_debugger(std::string& string, void *opq) {
  DbgSrv *db = (DbgSrv *)opq;

  db->msg_queue_.push_front(string);
  uv_async_send(&db->dbgsrv_send_);
}

bool DbgSrv::start(int port) {
  struct sockaddr_in addr;

  if (status_ != dbgsrv_offline) {
    return false;
  }

  if (port != (uint16_t)port) {
    return false;
  }

  // Set up the TCP Connection.
  uv_tcp_init(&dbgsrv_loop_, &dbgsrv_serv_);
  uv_ip4_addr("127.0.0.1", port, &addr);
  if (uv_tcp_bind(&dbgsrv_serv_, (const struct sockaddr*)&addr, 0)) {
    uv_close((uv_handle_t *)&dbgsrv_serv_, NULL);
    perror("bind");
    return false;
  }

  if (port == 0) {
    int addrlen = sizeof(addr);
    if (uv_tcp_getsockname(&dbgsrv_serv_, (struct sockaddr*)&addr, &addrlen)) {
      uv_close((uv_handle_t *)&dbgsrv_serv_, NULL);
      perror("getsockname");
      return false;
    }
    dbgsrv_port_ = ntohs(addr.sin_port);
  } else {
    dbgsrv_port_ = port;
  }

  if (uv_listen((uv_stream_t *)&dbgsrv_serv_, 0, dbgsrv_do_serv)) {
    uv_close((uv_handle_t *)&dbgsrv_serv_, NULL);
    perror("listen");
    return false;
  }

  // Start V8 debugger
  v8_.debugger_init(recv_from_debugger, this);

  // Start the Debug Server Loop
  uv_async_init(&dbgsrv_loop_, &dbgsrv_stop_, dbgsrv_do_stop);
  uv_thread_create(&dbgsrv_thread_, dbgsrv, this);

  status_ = dbgsrv_started;
  return true;
}

}  // namespace v8eval
