unpack = table.unpack

source_date_epoch = 1000000000

env = {
    "SOURCE_DATE_EPOCH=" .. source_date_epoch
}

function paste(arr)
    local s = ""
    for i, v in ipairs(arr) do
        s = s .. " " .. v
    end
    return s
end

function ls(dir)
    local cmd = {
        "/usr/bin/ls",
        dir,
        "2>/dev/null"
    }
    local fd = io.popen(paste(cmd))
    local arr = {}
    for line in fd:lines() do
        table.insert(arr, line)	
    end
    fd:close()
    return arr
end

function strip(dir, ...)
    local arr = ls(dir)
    for _, file in ipairs(arr) do     
        local cmd = {
            "/usr/bin/strip",
            ...,
            file
        }  
        os.execute(paste(cmd))
    end
end

function rm(file)
    local cmd = {
        "/usr/bin/rm",
        "--recursive",
        file,
        "2>/dev/null"
    }
    os.execute(paste(cmd))
end

function compress(file)
    local cmd = {
        "/usr/bin/xz",
        "--threads=0",
        "--force",
        file
    }
    os.execute(paste(cmd))
    rm(file)
end

function makepkg(dir)
    --cleanup
    strip(dir .. "/usr/lib64", "--strip-debug") 
    strip(dir .. "/usr/bin",   "--strip-all")
    strip(dir .. "/bin",       "--strip-all")
    rm(dir .. "/usr/share/doc")
    rm(dir .. "/usr/doc")
    rm(dir .. "/usr/share/info")

    --delete pyc files for reproducibility
    local cmd = {
        "/usr/bin/find",
        ".",
        "-name",
        "'.pyc'",
        "-delete"
    }
    os.execute(paste(cmd))

    --make tarball
    local cmd = {
        "/usr/bin/tar",
        "--directory",
        dir,
        "--sort=name",
        "--mtime=@" .. source_date_epoch,
        "--owner=0",
        "--group=0",
        "--numeric-owner",
        "--create",
        "--file",
        dir .. ".tar",
        unpack(ls(dir))
    }
    os.execute(paste(cmd))
    
    --compress
    compress(dir .. ".tar")
end

makepkg("/home/pac/Downloads/test")

extract = {
    "/usr/bin/tar",
    "--directory", "/",
    "--extract",
    "--verbose",
    "--file"
}

