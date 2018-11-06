FROM golang:1.10.4

# install pyenv
RUN git clone -b v1.2.7 https://github.com/pyenv/pyenv.git /.pyenv
ENV PYENV_ROOT /.pyenv
ENV PATH ${PYENV_ROOT}/bin:${PATH}

# install essentials to build python
RUN apt-get update
RUN apt-get install -y \
  build-essential \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  openssl \
  python-dev \
  zlib1g-dev

# install python
ENV PYVER 2.7.15
RUN pyenv install ${PYVER}
RUN pyenv global ${PYVER}

# install rbenv
RUN git clone -b v1.1.1 https://github.com/rbenv/rbenv.git /.rbenv
ENV RBENV_ROOT /.rbenv
ENV PATH ${RBENV_ROOT}/bin:${RBENV_ROOT}/shims:${PATH}

# install ruby-build
RUN mkdir -p "$(rbenv root)"/plugins
RUN git clone -b v20180822 https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

# install ruby
ENV RBVER 2.5.1
RUN rbenv install ${RBVER}
RUN rbenv global ${RBVER}

# install cmake
RUN apt-get install -y cmake

# install swig
RUN apt-get install -y \
  autoconf \
  automake \
  bison \
  g++ \
  libpcre3-dev \
  libtool \
  yodl
RUN git clone https://github.com/swig/swig.git /.swig
RUN cd /.swig && ./autogen.sh && ./configure && make && make install

# test v8eval
ADD . ${GOPATH}/src/github.com/sony/v8eval
WORKDIR ${GOPATH}/src/github.com/sony/v8eval
RUN ./build.sh test
RUN go/build.sh test
RUN python/build.sh test
RUN ruby/build.sh test
