$VERSION = (Get-Content VERSION) + "-win-amd64"
$REPO='hwdef'

function init {
    New-Item -Path '_output\bin\amd64\win' -ItemType Directory -Force
    New-Item -Path '_output\release' -ItemType Directory -Force
}

function bin {
    init
    go build -o .\_output\bin\amd64\win\demo.exe
}

function image {
    bin
    docker build -t $REPO/demo:$VERSION -f .\Dockerfile.win .
}

function push {
    image
    docker push $REPO/demo:$VERSION
}

function release{
    image
    docker save -o .\_output\release\demo-win-amd64.tar $REPO:demo:$VERSION
}

function clean {
    Remove-Item '_output' -Recurse
}


switch ($args)
{
    'init' {init}
    'bin' {bin}
    'image' {image}
    'push' {push}
    'release' {release}
    'clean' {clean}
}
