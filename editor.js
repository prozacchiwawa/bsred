edit = require('./src/runedit.bs.js');

var keymap = {
    '\x08': 'backspace',
    '\x09': 'tab',
    '\x0d': 'return',
    '\x1b': 'escape',
    'Enter': 'return',
    ' ': 'space',
    '!': 'exclamation_mark',
    '"': 'double_quote',
    '#': 'hash',
    '$': 'dollar',
    '%': 'percent',
    '&': 'amersand',
    "'": 'quote',
    '(': 'left_parenthesis',
    ')': 'right_parenthesis',
    '_': 'underscore',
    '`': 'backquote',
    '*': 'star',
    '^': 'caret',
    '+': 'plus',
    ',': 'comma',
    '-': 'minus',
    '.': 'period',
    '\\': 'antislash',
    '/': 'slash',
    ':': 'colon',
    ';': 'semicolon',
    '<': 'left_chevron',
    '=': 'equal',
    '>': 'right_chevron',
    '?': 'question_mark',
    '{': 'left_brace',
    '|': 'pipe',
    '}': 'right_brace',
    '[': 'left_bracket',
    ']': 'right_bracket',
    '~': 'tilde',
    'ArrowRight': 'right',
    'ArrowLeft': 'left',
    'ArrowUp': 'up',
    'ArrowDown': 'down',
    'code_33': 'page_up',
    'code_34': 'page_down',
    'code_35': 'end',
    'code_36': 'home',
    'code_37': 'left',
    'code_38': 'up',
    'code_39': 'right',
    'code_40': 'down',
    'code_45': 'insert',
    'code_46': 'delete'
};

var cancelShift = {
    'exclamation_mark': true,
    'double_quote': true,
    'hash': true,
    'dollar': true,
    'percent': true,
    'amersand': true,
    'left_parenthesis': true,
    'right_parenthesis': true,
    'underscore': true,
    'backquote': true,
    'star': true,
    'plus': true,
    'comma': true,
    'minus': true,
    'period': true,
    'slash': true,
    'caret': true,
    'colon': true,
    'semicolon': true,
    'left_chevron': true,
    'equal': true,
    'right_chevron': true,
    'question_mark': true,
    'pipe': true,
    'tilde': true,
    'antislash': true,
    'left_brace': true,
    'leff_bracket': true,
    'right_brace': true,
    'right_bracket': true
};

function mapKey(evt) {
    var s = '';
    var ctrl = evt.ctrlKey;
    var alt = evt.altKey;
    var shift = evt.shiftKey;

    if (keymap[evt.key]) {
        s = keymap[evt.key];
    } else if (evt.key.length == 1 && evt.key.charCodeAt(0) >= 48 && evt.key.charCodeAt(0) < 58) {
        s = 'digit_' + evt.key;
    } else if (evt.key.length == 1 && evt.key.charCodeAt(0) >= 65 && evt.key.charCodeAt(0) < 65 + 26) {
        shift = false;
        s = 'letter_' + evt.key;
    } else if (evt.key.length == 1 && evt.key.charCodeAt(0) >= 97 && evt.key.charCodeAt(0) < 97 + 26) {
        shift = false;
        s = 'letter_' + evt.key;
    } else if (keymap['code_'+evt.keyCode]) {
        s = keymap['code_'+evt.keyCode];
    } else if (evt.keyCode >= 112 && evt.keyCode < 112 + 12) {
        s = keymap['f' + (evt.keyCode - 111)];
    } else if (evt.key.length > 0 && evt.key.charCodeAt(0) < 32) {
        s = String.fromCharCode(evt.key.charCodeAt(0) + 96);
    } else {
        s = '' + evt.key;
    }

    if (s !== '' && shift && !cancelShift[s]) {
        s = "shift_" + s;
    }

    if (s !== '' && alt) {
        s = "alt_" + s;
    }

    if (s !== '' && ctrl) {
        s = "ctrl_" + s;
    }

    var prefix = s;

    if (s.length > 0) {
        s = s.charAt(0).toUpperCase() + s.substr(1);
    }

    console.log('evt ' + evt.key + ' -> ' + s + ' was ' + prefix);

    return s;
};

function replaceCharIn(str, n, ch) {
    return str.substr(0,n) + ch + str.substr(n+1);
}

function Editor(fme,edt) {
    this.sizeX = 80;
    this.sizeY = 24;
    this.focusme = document.getElementById(fme);
    this.editor = document.getElementById(edt);
    this.editobj = edit.createEditor({
        filename: 'hi.txt', filedata: '(* Foo fun *)\nlet x = 3'
    });
    this.frameobj = edit.createFrame({ frameX: this.sizeX, frameY: this.sizeY });
    this.rows = [];
    this.attributes = [];

    this.editor.addEventListener('click', (evt) => {
        console.log('focus');
        this.focusme.focus();
    });
    this.focusme.addEventListener('focus', (evt) => {
        console.log('focused');
    });
    this.focusme.addEventListener('blur', (evt) => {
        console.log('blurred');
    });

    this.focusme.addEventListener('keydown', (evt) => {
        evt.preventDefault();
        evt.stopPropagation();
        var events = edit.acceptKeyEvent({
            acceptEditor: this.editobj,
            acceptFrame: this.frameobj,
            acceptKey: mapKey(evt)
        });
        this.renderEvents(events);
    });
};

Editor.prototype.refresh = function() {
    var events = edit.rerender({
        acceptEditor: this.editobj,
        acceptFrame: this.frameobj,
        acceptKey: ''
    });
    this.renderEvents(events);
}

Editor.prototype.renderEvents = function(events) {
    for (var i = 0; i < events.length; i++) {
        var event = events[i];
        if (event.t == 'c') {
            if (!this.rows[event.y]) {
                this.rows[event.y] = '';
            }
            var theString = this.rows[event.y];
            while (event.x > theString.length) {
                theString = theString + ' ';
            }
            this.rows[event.y] = replaceCharIn(theString, event.x, event.c);
            this.attributes[event.y * this.sizeX + event.x] = [event.fg,event.bg];
        }
    }

    while (this.editor.childNodes.length > 0) {
        this.editor.removeChild(this.editor.childNodes[0]);
    }

    for (var i = 0; i < this.sizeY; i++) {
        var div = document.createElement('pre');
        var text = this.rows[i] === undefined ? '~' : this.rows[i];
        div.setAttribute('class','editor-row');
        div.appendChild(document.createTextNode(text));
        this.editor.appendChild(div);
    }
}

var editor = new Editor('focusme','editor');
editor.refresh();