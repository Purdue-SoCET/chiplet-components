import yaml, sys, os, subprocess

fusesoc_pad_dirs = int(sys.argv[2])
edayml = sys.argv[1]

buildroot = os.path.dirname(edayml)
subprocess.check_output(["mkdir", buildroot + "/" + "tb_output_files"])
with open(edayml) as stream:
    try:
        edainfo = yaml.safe_load(stream)
        for file in edainfo["files"]:
            if file["file_type"] == "user":
                newfile = buildroot + "/" + "/".join(file["name"].split("/")[fusesoc_pad_dirs:])
                oldfile = buildroot + "/" + file["name"]
                subprocess.run(["mkdir", "-p", os.path.dirname(newfile)])
                subprocess.run(["cp", oldfile, newfile])
    except yaml.YAMLError as exc:
        print("Error reading .eda.yml")

