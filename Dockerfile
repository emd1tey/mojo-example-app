# https://github.com/modularml/mojo/blob/main/examples/docker/Dockerfile.mojosdk
# ===----------------------------------------------------------------------=== #
# Copyright (c) 2023, Modular Inc. All rights reserved.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #

# Example command line:
# Use no-cache to force docker to rebuild layers of the image by downloading the SDK from the repos
# docker build --no-cache \
#    --build-arg AUTH_KEY=<your-modular-auth-key>
#    --pull -t modular/mojo-v0.2-`date '+%Y%d%m-%H%M'` \
#    --file Dockerfile.mojosdk .

FROM ubuntu:20.04

ARG DEFAULT_TZ=America/Los_Angeles
ENV DEFAULT_TZ=$DEFAULT_TZ
ARG MODULAR_HOME=/home/user/.modular
ENV MODULAR_HOME=$MODULAR_HOME
ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update -qq && apt-get upgrade -y && \
    apt-get install -y apt-utils curl sudo git && \
    apt-get install -y libedit2 libncurses-dev apt-transport-https \
      ca-certificates gnupg libxml2-dev python3 python3-pip python3-dev python3-venv wget && \
    apt-get clean


RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-py38_23.5.2-0-Linux-x86_64.sh > /tmp/miniconda.sh \
    && chmod +x /tmp/miniconda.sh \
    && /tmp/miniconda.sh -b -p /opt/conda

ENV PATH=/opt/conda/bin:$PATH
RUN conda init

ARG AUTH_KEY=5ca1ab1e
ENV AUTH_KEY=$AUTH_KEY

RUN curl https://get.modular.com | sh - && \
    modular auth $AUTH_KEY 
RUN modular install mojo

RUN useradd -m -u 1000 user
RUN chown -R user $MODULAR_HOME

ENV PATH="$MODULAR_HOME/pkg/packages.modular.com_mojo/bin:$PATH"

RUN pip install \
    jupyterlab \
    ipykernel \
    matplotlib \
    ipywidgets \
    gradio 

USER user
WORKDIR $HOME/app

COPY --chown=user . $HOME/app
#RUN wget -c https://huggingface.co/karpathy/tinyllamas/resolve/main/stories15M.bin
#RUN wget -c https://huggingface.co/karpathy/tinyllamas/resolve/main/stories42M.bin
#RUN wget -c https://huggingface.co/karpathy/tinyllamas/resolve/main/stories110M.bin

#CMD mojo llama2.mojo stories15M.bin -s 99 -n 256 -t 0.5 -i "Llama is an animal"
CMD ["python3", "gradio_app.py"]
