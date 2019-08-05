# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright 2019 Clairvoyant, LLC.

VERSION-CSD = $(shell bash ./version)
VERSION-PARCEL = $(shell bash ./version-parcel)
PACKAGE_NAME = AIRFLOW-$(VERSION-CSD)
SHA_CMD := $(shell { command -v sha1sum || command -v sha1 || command -v shasum; } 2>/dev/null)

.PHONY: help dist validate clean
help:
	@echo 'Please use "make <target>" where <target> is one of:'
	@echo '  dist     : Create a CSD jarfile'
	@echo '  validate : Run unit tests'
	@echo '  clean    : Clean up all generated files'

dist: clean validate
	@mkdir -p target/$(PACKAGE_NAME)
	@echo "*** Building CSD jarfile ..."
	cp -pr src/{aux,descriptor,images,scripts} target/$(PACKAGE_NAME)
	sed -e 's|{{ version }}|$(VERSION-CSD)|' -e 's|{{ parcel_version }}|$(VERSION-PARCEL)|' \
		src/descriptor/service.sdl >target/$(PACKAGE_NAME)/descriptor/service.sdl

	jar -cvf target/$(PACKAGE_NAME).jar -C target/$(PACKAGE_NAME) .
	$(SHA_CMD) target/$(PACKAGE_NAME).jar | awk '{ print $$1 }' > target/$(PACKAGE_NAME).jar.sha
	@echo "*** complete"

validate: src/descriptor/service.sdl
	@echo "*** Validating service config ..."
	@java -jar ../../cloudera/cm_ext/validator/target/validator.jar -s src/descriptor/service.sdl

validate-mdl: src/descriptor/service.mdl
	@echo "*** Validating monitor config ..."
	@java -jar ../../cloudera/cm_ext/validator/target/validator.jar -z src/descriptor/service.mdl

clean:
	rm -rf target
