import glob
import os
from pathlib import Path
from cocotb_tools.runner import get_runner

RTL_DIRS = (
    "/foss/designs/axi2apb/rtl",
)
LANGUAGE = os.getenv("HDL_TOPLEVEL_LANG", "verilog").lower().strip()
WAVES = os.getenv("WAVES", default=False)
ASSERTIONS = os.getenv("ASSERTIONS", default=True)

def get_rtl_files(lang):
    rtl_files = []
    if lang == "verilog":
        for rootdir in RTL_DIRS:
            rtl_files += list(glob.glob(f"{rootdir}/**/*.v", recursive=True))
            rtl_files += list(glob.glob(f"{rootdir}/**/*.sv", recursive=True))
    else:
        raise NotImplementedError
    
    # remove duplicates, while preserving order (defines must be first)
    rtl_files = list(map(lambda x: Path(x), rtl_files))
    seen = set()
    rtl_files = [x for x in rtl_files if not (x in seen or seen.add(x))]
    return rtl_files
