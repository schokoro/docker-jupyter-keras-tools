FROM nvidia/cuda:10.2-devel-ubuntu18.04

LABEL maintainer="Roman Suvorov windj007@gmail.com"

RUN apt-get clean && apt-get update && apt-get install -yqq curl && apt-get clean

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash

RUN ln -fs /usr/share/zoneinfo/Russia/Moscow /etc/localtime
ENV DEBIAN_FRONTEND noninteractive

# https://github.com/pyenv/pyenv/wiki#suggested-build-environment see at the required dependencies for pyenv
RUN apt-get install -yqq build-essential cmake curl gfortran git graphviz libatlas-base-dev \
        libatlas3-base libblas-dev libbz2-dev libffi-dev libfreetype6-dev libhdf5-dev liblapack-dev \
        liblapacke-dev liblzma-dev libncurses5-dev libpng-dev libreadline-dev libsqlite3-dev \
        libssl-dev libxml2-dev libxmlsec1-dev libxslt-dev llvm locales make nano nodejs pkg-config \
        tk-dev tmux tzdata wget xz-utils zlib1g-dev  && apt-get clean

ENV PYENV_ROOT /opt/.pyenv
RUN curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
ENV PATH /opt/.pyenv/shims:/opt/.pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN pyenv install 3.7.7
RUN pyenv global 3.7.7

RUN pip  install -U pip

# thanks to libatlas-base-dev (base! not libatlas-dev), it will link to atlas
RUN python -m pip install -U cython && \ 
        python -m pip install -U numpy && \ 
        python -m pip install allennlp annoy bigartm bokeh category_encoders dask[complete] eli5 \ 
        fastcluster fire fitter flair forestci gensim graphviz grpcio h5py hdbscan hydra-core \ 
        imbalanced-learn imgaug install joblib jupyter jupyter_contrib_nbextensions \ 
        jupyter_nbextensions_configurator jupyterlab keras keras-vis line_profiler lxml matplotlib \ 
        mlxtend mpld3 networkx nltk nmslib opencv-python pandarallel pandas pandas-profiling patool \ 
        plotly pprofile pydot pymorphy2-dicts-ru pymorphy2[fast] pymystem3 pyprind pytorch-transformers \ 
        sacred scikit-image scikit-learn scipy seaborn seqeval sharedmem sklearn \ 
        sklearn_crfsuite skorch spacy tables tensorboardX tensorflow-gpu torch torchtext torchvision \ 
        tqdm transformers ujson xeus-python xgboost \ 
        git+https://github.com/IINemo/active_learning_toolbox git+https://github.com/IINemo/isanlp.git \ 
        git+https://github.com/IINemo/libact/#egg=libact git+https://github.com/facebookresearch/fastText.git \ 
        git+https://github.com/marcotcr/lime git+https://github.com/openai/gym git+https://github.com/pybind/pybind11.git && \ 
        python -c "import shutil ; shutil.rmtree('/root/.cache')" 

RUN pip install deeppavlov --no-deps && python -c "import shutil ; shutil.rmtree('/root/.cache')"

RUN python -c "import pymystem3 ; pymystem3.Mystem()"  &&  \ 
        python -m nltk.downloader popular && \ 
        python -m spacy download en_core_web_sm && \ 
        python -m spacy download xx_ent_wiki_sm

RUN pyenv rehash

RUN jupyter contrib nbextension install --system && \
    jupyter nbextensions_configurator enable --system && \
    jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
    jupyter labextension install @jupyterlab/toc && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager

RUN git clone --recursive https://github.com/Microsoft/LightGBM /tmp/lgbm && \
    cd /tmp/lgbm && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    cd ../python-package && \
    python setup.py install && \
    cd /tmp && \
    rm -r /tmp/lgbm

RUN git clone https://code.googlesource.com/re2 /tmp/re2 && \
    cd /tmp/re2 && \
    make CFLAGS='-fPIC -c -Wall -Wno-sign-compare -O3 -g -I.' && \
    make test && \
    make install && \
    make testinstall && \
    ldconfig && \
    pip install -U fb-re2 && \ 
    rm -r /tmp/re2

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
        dpkg-reconfigure --frontend=noninteractive locales

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

EXPOSE 8888
VOLUME ["/notebook", "/jupyter/certs"]
WORKDIR /notebook

ADD test_scripts /test_scripts
ADD jupyter /jupyter
COPY entrypoint.sh /entrypoint.sh
COPY hashpwd.py /hashpwd.py

ENV JUPYTER_CONFIG_DIR="/jupyter"

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "jupyter", "lab", "--ip=0.0.0.0", "--allow-root" ]
EXPOSE 8888
