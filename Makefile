install-service:
	@mkdir -p /var/log/coe113labchecker
	@chmod +x ./scripts/*.sh
	@cp scripts/*.sh /usr/local/bin
	@cp scripts/*.service /etc/systemd/system
	@systemctl daemon-reload
	@systemctl enable coe113.laboratory.checker.service
	@systemctl start coe113.laboratory.checker.service
	@echo "Displaying status of service in 10 secs..."
	@sleep 10
	systemctl status coe113.laboratory.checker.service