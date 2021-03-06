# Copyright 2018 Slightech Co., Ltd. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
include CommonDefs.mk

.DEFAULT_GOAL := help

help:
	@echo "Usage:"
	@echo "  make help            show help message"
	@echo "  make apidoc          make api doc"
	@echo "  make opendoc         open api doc (html)"
	@echo "  make init            init project"
	@echo "  make build           build project"
	@echo "  make test            build test and run"
	@echo "  make install         install project"
	@echo "  make samples         build samples"
	@echo "  make tools           build tools"
	@echo "  make ros             build ros wrapper"
	@echo "  make clean|cleanall  clean generated or useless things"

.PHONY: help

all: test tools samples

.PHONY: all

# doc

apidoc:
	@$(call echo,Make $@)
	@[ -e ./_install/include ] || $(MAKE) install
	@$(SH) ./doc/build.sh

opendoc: apidoc
	@$(call echo,Make $@)
	@$(shell $(SH) ./doc/langs.sh 1); \
	for lang in "$${LANGS[@]}"; do \
		html=./doc/_output/$$lang/html/index.html; \
		[ -f "$$html" ] && $(SH) ./scripts/open.sh $$html; \
	done

.PHONY: apidoc opendoc

# deps

submodules:
	@git submodule update --init

third_party: submodules
	@$(call echo,Make $@)
	@$(call echo,Make glog,33)
	@$(call cmake_build,./third_party/glog/_build)

.PHONY: submodules third_party

# init

init: submodules
	@$(call echo,Make $@)
	@$(SH) ./scripts/init.sh

.PHONY: init

# build

build: third_party
	@$(call echo,Make $@)
	@$(call cmake_build,./_build)

.PHONY: build

# test

test: install
	@$(call echo,Make $@)
	@$(call echo,Make gtest,33)
ifeq ($(HOST_OS),Win)
	@$(call cmake_build,./test/gtest/_build,..,-Dgtest_force_shared_crt=ON)
else
	@$(call cmake_build,./test/gtest/_build)
endif
	@$(call echo,Make test,33)
	@$(call cmake_build,./test/_build)
ifeq ($(HOST_OS),Win)
	@.\\\test\\\_output\\\bin\\\mynteye_test.bat
else
	@./test/_output/bin/mynteye_test
endif

.PHONY: test

# install

install: build
	@$(call echo,Make $@)
ifeq ($(HOST_OS),Win)
ifneq ($(HOST_NAME),MinGW)
	@cd ./_build; msbuild.exe INSTALL.vcxproj /property:Configuration=Release
else
	@cd ./_build; make install
endif
else
	@cd ./_build; make install
endif

.PHONY: install

# samples

samples: install
	@$(call echo,Make $@)
	@$(call cmake_build,./samples/_build)

.PHONY: samples

# tools

tools: install
	@$(call echo,Make $@)
	@$(call cmake_build,./tools/_build)

.PHONY: tools

# ros

ros: install
	@$(call echo,Make $@)
ifeq ($(HOST_OS),Win)
	$(error "Can't make ros on win")
else
	@cd ./wrappers/ros && catkin_make
endif

.PHONY: ros

cleanros:
	@$(call echo,Make $@)
	@$(call rm,./wrappers/ros/build/)
	@$(call rm,./wrappers/ros/devel/)
	@$(call rm,./wrappers/ros/install/)
	@$(call rm,./wrappers/ros/.catkin_workspace)
	@$(call rm,./wrappers/ros/src/CMakeLists.txt)
	@$(call rm_f,*INFO*,$(HOME)/.ros/)
	@$(call rm_f,*WARNING*,$(HOME)/.ros/)
	@$(call rm_f,*ERROR*,$(HOME)/.ros/)
	@$(call rm_f,*FATAL*,$(HOME)/.ros/)

.PHONY: cleanros

# clean

clean:
	@$(call echo,Make $@)
	@$(call rm,./_build/)
	@$(call rm,./_output/)
	@$(call rm,./_install/)
	@$(call rm,./samples/_build/)
	@$(call rm,./samples/_output/)
	@$(call rm,./tools/_build/)
	@$(call rm,./tools/_output/)
	@$(call rm,./test/_build/)
	@$(call rm,./test/_output/)
	@$(MAKE) cleanlog
ifeq ($(HOST_OS),Linux)
	@$(MAKE) cleanros
endif

cleanlog:
	@$(call rm_f,*INFO*)
	@$(call rm_f,*WARNING*)
	@$(call rm_f,*ERROR*)
	@$(call rm_f,*FATAL*)

cleanall: clean
	@$(call rm,./doc/_output/)
	@$(call rm,./test/gtest/_build/)
	@$(call rm,./third_party/glog/_build/)
	@$(FIND) . -type f -name ".DS_Store" -print0 | xargs -0 rm -f

.PHONY: clean cleanlog cleanall

# others

host:
	@$(call echo,Make $@)
	@echo HOST_OS: $(HOST_OS)
	@echo HOST_ARCH: $(HOST_ARCH)
	@echo HOST_NAME: $(HOST_NAME)
	@echo SH: $(SH)
	@echo ECHO: $(ECHO)
	@echo FIND: $(FIND)
	@echo CC: $(CC)
	@echo CXX: $(CXX)
	@echo MAKE: $(MAKE)
	@echo BUILD: $(BUILD)
	@echo LDD: $(LDD)
	@echo CMAKE: $(CMAKE)

.PHONY: host

cpplint: submodules
	@$(call echo,Make $@)
	@$(SH) ./scripts/$@.sh

.PHONY: cpplint
