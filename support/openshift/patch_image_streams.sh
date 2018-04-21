#!/bin/sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
sed 's/registry.access.redhat.com\/rhpam-7/registry.access.redhat.com\/rhpam-7-tech-preview/g' $SCRIPT_DIR/rhpam70-image-streams.yaml > $SCRIPT_DIR/rhpam70-image-streams-tech-preview.yaml
