# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# HMS Build changed charts configuration
HMS_BUILD_CHANGED_CHARTS_ACTION_BRANCH ?= CASMHMS-5597

# Helm Chart
TARGET_BRANCH ?= main
UNSTABLE_BUILD_SUFFIX ?= "" # If this variable is the empty string, then this is a stable build
							# Otherwise, if this variable is non-empty then this is an unstable build

all-charts: vendor/hms-build-changed-charts-action
	./vendor/hms-build-changed-charts-action/scripts/build_all_charts.sh ./charts

vendor/hms-build-changed-charts-action:
	mkdir -p vendor
	git clone git@github.com:Cray-HPE/hms-build-changed-charts-action.git vendor/hms-build-changed-charts-action --branch ${HMS_BUILD_CHANGED_CHARTS_ACTION_BRANCH}

	./vendor/hms-build-changed-charts-action/scripts/verify_build_environment.sh

changed-charts: vendor/hms-build-changed-charts-action ct-config
	./vendor/hms-build-changed-charts-action/scripts/build_changed_charts.sh ./charts ${TARGET_BRANCH}
	
ct-config: vendor/hms-build-changed-charts-action
	git checkout -- ct.yaml
	./vendor/hms-build-changed-charts-action/scripts/update-ct-config-with-chart-dirs.sh charts

lint: vendor/hms-build-changed-charts-action ct-config
	ct lint --config ct.yaml

clean: vendor/hms-build-changed-charts-action
	git checkout -- ct.yaml
	./vendor/hms-build-changed-charts-action/scripts/clean_all_charts.sh ./charts
	rm -rf .packaged
