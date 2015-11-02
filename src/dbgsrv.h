#ifndef DBGSRV_H_
#define DBGSRV_H_

#include "uv.h"
#include <string>
#include <list>

namespace v8eval {

class _V8;

/// \class DbgSrv
///
/// A debugger server is associated to a _V8 instance and accepts
/// TCP/IP connections to exchange messages in the V8 debugger
/// protocol.
class DbgSrv {
 public:
  DbgSrv(_V8& v8);
  ~DbgSrv();

  /// \brief Starts a debugger server
  /// \param port TCP/IP port the server will listen
  /// \return success or not as boolean
  ///
  /// The port can be set to 0 to have a port automatically assigned.
  bool start(int port);

  /// \brief Get the TCP/IP port the system is currently listening from
  /// \return A TCP/IP port or 0 if not currently set.
  inline int get_port() { return dbgsrv_port_; }

 private:
  static void recv_from_debugger(std::string& string, void *opq);

  static void dbgsrv_do_clnt(uv_stream_t *client, ssize_t nread, const uv_buf_t *buf);
  static void dbgsrv_do_send(uv_async_t *async);
  static void dbgsrv_do_serv(uv_stream_t *server, int status);
  static void dbgsrv_do_stop(uv_async_t *async);
  static void dbgsrv(void *);

  static void dbgproc_do_proc(uv_async_t *);
  static void dbgproc_do_stop(uv_async_t *);
  static void dbgproc(void *);

 private:
  _V8& v8_;

  enum {
    dbgsrv_offline,
    dbgsrv_started,
    dbgsrv_connected
  } status_;
  std::list<std::string> msg_queue_;

  int dbgsrv_port_;
  uv_tcp_t dbgsrv_serv_;
  uv_tcp_t dbgsrv_clnt_;
  uv_async_t dbgsrv_send_;
  uv_async_t dbgsrv_stop_;
  uv_thread_t dbgsrv_thread_;
  uv_loop_t dbgsrv_loop_;

  uv_async_t dbgproc_proc_;
  uv_async_t dbgproc_stop_;
  uv_thread_t dbgproc_thread_;
  uv_loop_t dbgproc_loop_;
};

}  // namespace v8eval

#endif  // DBGSRV_H_
