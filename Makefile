all: build check_convention

clean:
	rm -fr build

check_convention:
	pep8 . --max-line-length=109

test-server:
	RACKATTACK_PROVIDER=tcp://rackattack-provider:1014@tcp://rackattack-provider:1015@http://rackattack-provider:1016 PYTHONPATH=py UPSETO_JOIN_PYTHON_NAMESPACES=yes python py/rackattack/dashboard/main.py --realtimewebuiRoot $(PWD)/../realtimewebui --dashboardRoot $(PWD)

test-cli:
	RACKATTACK_PROVIDER=tcp://localhost:1014@tcp://localhost:1015 PYTHONPATH=py UPSETO_JOIN_PYTHON_NAMESPACES=yes python py/rackattack/dashboard/cli.py

.PHONY: build
build: build/rackattack-physical-dashboard.egg

build/rackattack-physical-dashboard.egg: py/rackattack/dashboard/main.py
-include build/rackattack-physical-dashboard.egg.dep

build/%.egg:
	-mkdir $(@D)
	UPSETO_JOIN_PYTHON_NAMESPACES=yes PYTHONPATH=py:../realtimewebui/py python -m upseto.packegg --entryPoint=$< --output=$@ --createDeps=$@.dep --compile_pyc --joinPythonNamespaces

install: build
	-sudo systemctl stop rackattack-physical-dashboard.service
	-sudo mkdir -p /usr/share/rackattack-physical-dashboard/realtimewebui
	sudo cp build/*.egg /usr/share/rackattack-physical-dashboard
	sudo cp -r html /usr/share/rackattack-physical-dashboard/
	sudo cp -r js /usr/share/rackattack-physical-dashboard/
	sudo cp -r static /usr/share/rackattack-physical-dashboard/
	sudo cp -r ../realtimewebui/js ../realtimewebui/html ../realtimewebui/externals /usr/share/rackattack-physical-dashboard/realtimewebui
	sudo cp rackattack-physical-dashboard.service /usr/lib/systemd/system/rackattack-physical-dashboard.service
	sudo systemctl enable rackattack-physical-dashboard.service
	if ["$(DONT_START_SERVICE)" == ""]; then sudo systemctl start rackattack-physical-dashboard; fi

uninstall:
	-sudo systemctl stop rackattack-physical-dashboard
	-sudo systemctl disable rackattack-physical-dashboard.service
	-sudo rm -fr /usr/lib/systemd/system/rackattack-physical-dashboard.service
	sudo rm -fr /usr/share/rackattack-physical-dashboard
