#!/bin/bash
# Usage: ./load_to_clipboard.sh xml/01_create_customer.xml
#
# Loads a FileMaker XML snippet file onto the clipboard so you can
# paste it directly into FileMaker's Script Workspace (Cmd+V).

if [ -z "$1" ]; then
    echo "Usage: ./load_to_clipboard.sh <xml-file>"
    echo ""
    echo "Available scripts:"
    ls -1 xml/*.xml 2>/dev/null
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: File not found: $1"
    exit 1
fi

XML_CONTENT=$(cat "$1")

osascript -l JavaScript -e "
    ObjC.import('AppKit');
    var pb = $.NSPasteboard.generalPasteboard;
    pb.clearContents;
    var xmlString = $.NSString.stringWithString($(cat "$1" | sed "s/'/\\\\'/g" | tr '\n' ' '));
    pb.setStringForType(xmlString, $('dyn.ah62d4rv4gu8zg7puqz31a2ptrvy0635u'));
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Loaded '$1' to clipboard."
    echo "  Now open FileMaker Script Workspace, create a new script, and press Cmd+V."
else
    echo "JXA method failed, trying AppleScript..."
    osascript <<APPLESCRIPT
        use framework "AppKit"
        use scripting additions

        set xmlContent to read POSIX file "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")" as «class utf8»
        set pb to current application's NSPasteboard's generalPasteboard()
        pb's clearContents()
        pb's setString:xmlContent forType:"dyn.ah62d4rv4gu8zg7puqz31a2ptrvy0635u"
APPLESCRIPT

    if [ $? -eq 0 ]; then
        echo "✓ Loaded '$1' to clipboard."
        echo "  Now open FileMaker Script Workspace, create a new script, and press Cmd+V."
    else
        echo "Error: Could not set clipboard. Try the Python method below:"
        echo ""
        echo "  python3 -c \""
        echo "from AppKit import NSPasteboard, NSString"
        echo "pb = NSPasteboard.generalPasteboard()"
        echo "pb.clearContents()"
        echo "xml = open('$1').read()"
        echo "pb.setString_forType_(xml, 'dyn.ah62d4rv4gu8zg7puqz31a2ptrvy0635u')"
        echo "\""
    fi
fi
