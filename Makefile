# parsing `ls` output... I guess will break if spaces in path?
LATEST_RUN := runs/$(shell ls -t runs | head -n1)

# _horrible_ hack to get ENV_COMMAND out of OpenLane Makefile
harden:
	$(shell make -s -C $$OPENLANE_ROOT __wrapped_wiggly_harden \
		--eval '__wrapped_wiggly_harden:; echo $$(ENV_COMMAND)') \
		./flow.tcl -design wrapped_wiggly_ic_1

print_summary:
	summary.py --design wiggly_ic_1 --summary
print_timing:
	cat $(LATEST_RUN)/reports/synthesis/opensta.min_max.rpt
open_magic:
	cd $(LATEST_RUN)/results/magic/ && DISPLAY=:0 magic wiggly_ic_1.gds
