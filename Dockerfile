FROM golang:1.5.1

# install pyenv
RUN git clone git://github.com/yyuu/pyenv.git /.pyenv
ENV PYENV_ROOT /.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

# install essentials to build python and ruby
RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y bzip2 libbz2-dev
RUN apt-get install -y openssl libssl-dev
RUN apt-get install -y sqlite3 libsqlite3-dev
RUN apt-get install -y libreadline6 libreadline6-dev

# install python
ENV PYVER 2.7.10
RUN pyenv install $PYVER
RUN pyenv global $PYVER

# install rbenv and ruby-build
RUN git clone https://github.com/sstephenson/rbenv.git /usr/local/rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /usr/local/rbenv/plugins/ruby-build
ENV RBENV_ROOT /usr/local/rbenv
ENV PATH $RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH

# install ruby
ENV RBVER 2.2.3
RUN rbenv install $RBVER
RUN rbenv global $RBVER

# install cmake
RUN apt-get install -y cmake

# install swig
RUN apt-get install -y autoconf automake libtool
RUN apt-get install -y libpcre3-dev
RUN apt-get install -y bison
RUN apt-get install -y g++
RUN apt-get install -y yodl
RUN git clone https://github.com/swig/swig.git /.swig
RUN cd /.swig && ./autogen.sh && ./configure && make && make install

# install v8eval
ADD . $GOPATH/src/github.com/sony/v8eval
RUN $GOPATH/src/github.com/sony/v8eval/go/build.sh install
RUN $GOPATH/src/github.com/sony/v8eval/python/build.sh install
RUN $GOPATH/src/github.com/sony/v8eval/ruby/build.sh install

# test v8eval
RUN $GOPATH/src/github.com/sony/v8eval/build.sh test
RUN $GOPATH/src/github.com/sony/v8eval/go/build.sh test
RUN $GOPATH/src/github.com/sony/v8eval/python/build.sh test
RUN $GOPATH/src/github.com/sony/v8eval/ruby/build.sh test
