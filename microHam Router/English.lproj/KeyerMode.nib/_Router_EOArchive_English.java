// _Router_EOArchive_English.java
// Generated by EnterpriseObjects palette at Sunday, May 28, 2006 1:04:48 PM US/Pacific

import com.webobjects.eoapplication.*;
import com.webobjects.eocontrol.*;
import com.webobjects.eointerface.*;
import com.webobjects.eointerface.swing.*;
import com.webobjects.foundation.*;
import java.awt.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.table.*;
import javax.swing.text.*;

public class _Router_EOArchive_English extends com.webobjects.eoapplication.EOArchive {
    com.webobjects.eointerface.swing.EOTextField _nsTextField0, _nsTextField1, _nsTextField2, _nsTextField3, _nsTextField4, _nsTextField5;
    com.webobjects.eointerface.swing.EOView _nsBox0, _nsBox1, _nsBox2, _nsBox3, _nsCustomView0;
    javax.swing.JButton _nsButton0, _nsButton1;
    javax.swing.JCheckBox _nsButton2;

    public _Router_EOArchive_English(Object owner, NSDisposableRegistry registry) {
        super(owner, registry);
    }

    protected void _construct() {
        Object owner = _owner();
        EOArchive._ObjectInstantiationDelegate delegate = (owner instanceof EOArchive._ObjectInstantiationDelegate) ? (EOArchive._ObjectInstantiationDelegate)owner : null;
        Object replacement;

        super._construct();

        _nsBox3 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "NSView");
        _nsBox2 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "NSBox11");
        _nsTextField5 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField12");
        _nsTextField4 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField111");
        _nsButton1 = (javax.swing.JButton)_registered(new javax.swing.JButton("Unkey"), "");
        _nsButton0 = (javax.swing.JButton)_registered(new javax.swing.JButton("Key"), "");

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "errorString")) != null)) {
            _nsTextField3 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTextField)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsTextField3");
        } else {
            _nsTextField3 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField11");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "enableFlag")) != null)) {
            _nsButton2 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (javax.swing.JCheckBox)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsButton2");
        } else {
            _nsButton2 = (javax.swing.JCheckBox)_registered(new javax.swing.JCheckBox(""), "NSButton4");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "activeIndicator")) != null)) {
            _nsTextField2 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTextField)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsTextField2");
        } else {
            _nsTextField2 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField");
        }

        _nsTextField1 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField1");
        _nsBox1 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "NSView");
        _nsBox0 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "NSBox1");

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "controlView")) != null)) {
            _nsCustomView0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOView)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsCustomView0");
        } else {
            _nsCustomView0 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "Router View");
        }

        _nsTextField0 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField121");
    }

    protected void _awaken() {
        super._awaken();
        _nsButton1.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "testUnPTT", _nsButton1), ""));
        _nsButton0.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "testPTT", _nsButton0), ""));

        if (_replacedObjects.objectForKey("_nsTextField3") == null) {
            _connect(_owner(), _nsTextField3, "errorString");
        }

        if (_replacedObjects.objectForKey("_nsButton2") == null) {
            _connect(_owner(), _nsButton2, "enableFlag");
        }

        if (_replacedObjects.objectForKey("_nsCustomView0") == null) {
            _connect(_owner(), _nsCustomView0, "controlView");
        }

        if (_replacedObjects.objectForKey("_nsTextField2") == null) {
            _connect(_owner(), _nsTextField2, "activeIndicator");
        }
    }

    protected void _init() {
        super._init();
        if (!(_nsBox2.getLayout() instanceof EOViewLayout)) { _nsBox2.setLayout(new EOViewLayout()); }
        _nsBox3.setSize(125, 1);
        _nsBox3.setLocation(2, 2);
        ((EOViewLayout)_nsBox2.getLayout()).setAutosizingMask(_nsBox3, EOViewLayout.MinYMargin);
        _nsBox2.add(_nsBox3);
        _nsBox2.setBorder(new com.webobjects.eointerface.swing._EODefaultBorder("", true, "Lucida Grande", 13, Font.PLAIN));
        _setFontForComponent(_nsTextField5, "Verdana", 10, Font.PLAIN);
        _nsTextField5.setEditable(false);
        _nsTextField5.setOpaque(false);
        _nsTextField5.setText("PTT:");
        _nsTextField5.setHorizontalAlignment(javax.swing.JTextField.LEFT);
        _nsTextField5.setSelectable(false);
        _nsTextField5.setEnabled(true);
        _nsTextField5.setBorder(null);
        _setFontForComponent(_nsTextField4, "Verdana", 10, Font.PLAIN);
        _nsTextField4.setEditable(false);
        _nsTextField4.setOpaque(false);
        _nsTextField4.setText("Enable");
        _nsTextField4.setHorizontalAlignment(javax.swing.JTextField.LEFT);
        _nsTextField4.setSelectable(false);
        _nsTextField4.setEnabled(true);
        _nsTextField4.setBorder(null);
        _setFontForComponent(_nsButton1, "Lucida Grande", 11, Font.PLAIN);
        _nsButton1.setMargin(new Insets(0, 2, 0, 2));
        _setFontForComponent(_nsButton0, "Lucida Grande", 11, Font.PLAIN);
        _nsButton0.setMargin(new Insets(0, 2, 0, 2));

        if (_replacedObjects.objectForKey("_nsTextField3") == null) {
            _setFontForComponent(_nsTextField3, "Verdana", 10, Font.PLAIN);
            _nsTextField3.setEditable(false);
            _nsTextField3.setOpaque(false);
            _nsTextField3.setText("");
            _nsTextField3.setHorizontalAlignment(javax.swing.JTextField.LEFT);
            _nsTextField3.setSelectable(false);
            _nsTextField3.setEnabled(true);
            _nsTextField3.setBorder(null);
        }

        if (_replacedObjects.objectForKey("_nsButton2") == null) {
            _setFontForComponent(_nsButton2, "Verdana", 11, Font.PLAIN);
        }

        if (_replacedObjects.objectForKey("_nsTextField2") == null) {
            _setFontForComponent(_nsTextField2, "Lucida Grande", 13, Font.PLAIN);
            _nsTextField2.setEditable(false);
            _nsTextField2.setOpaque(true);
            _nsTextField2.setText("");
            _nsTextField2.setHorizontalAlignment(javax.swing.JTextField.LEFT);
            _nsTextField2.setSelectable(false);
            _nsTextField2.setEnabled(true);
        }

        _setFontForComponent(_nsTextField1, "Verdana", 11, Font.PLAIN);
        _nsTextField1.setEditable(false);
        _nsTextField1.setOpaque(false);
        _nsTextField1.setText("");
        _nsTextField1.setHorizontalAlignment(javax.swing.JTextField.LEFT);
        _nsTextField1.setSelectable(false);
        _nsTextField1.setEnabled(true);
        _nsTextField1.setBorder(null);
        if (!(_nsBox0.getLayout() instanceof EOViewLayout)) { _nsBox0.setLayout(new EOViewLayout()); }
        _nsBox1.setSize(125, 1);
        _nsBox1.setLocation(2, 2);
        ((EOViewLayout)_nsBox0.getLayout()).setAutosizingMask(_nsBox1, EOViewLayout.MinYMargin);
        _nsBox0.add(_nsBox1);
        _nsBox0.setBorder(new com.webobjects.eointerface.swing._EODefaultBorder("", true, "Lucida Grande", 13, Font.PLAIN));

        if (_replacedObjects.objectForKey("_nsCustomView0") == null) {
            if (!(_nsCustomView0.getLayout() instanceof EOViewLayout)) { _nsCustomView0.setLayout(new EOViewLayout()); }
            _nsBox0.setSize(268, 5);
            _nsBox0.setLocation(63, 68);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsBox0, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsBox0);
            _nsTextField1.setSize(129, 17);
            _nsTextField1.setLocation(70, 48);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField1, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField1);
            _nsTextField2.setSize(16, 9);
            _nsTextField2.setLocation(70, 53);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField2, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField2);
            _nsButton2.setSize(39, 19);
            _nsButton2.setLocation(59, 88);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsButton2, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsButton2);
            _nsTextField4.setSize(40, 17);
            _nsTextField4.setLocation(96, 89);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField4, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField4);
            _nsButton0.setSize(50, 20);
            _nsButton0.setLocation(107, 178);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsButton0, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsButton0);
            _nsButton1.setSize(50, 20);
            _nsButton1.setLocation(172, 178);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsButton1, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsButton1);
            _nsTextField5.setSize(58, 17);
            _nsTextField5.setLocation(70, 180);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField5, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField5);
            _nsBox2.setSize(268, 5);
            _nsBox2.setLocation(63, 123);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsBox2, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsBox2);
            _nsTextField3.setSize(223, 17);
            _nsTextField3.setLocation(112, 49);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField3, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField3);
            _nsTextField0.setSize(92, 17);
            _nsTextField0.setLocation(70, 146);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField0, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField0);
        }

        _setFontForComponent(_nsTextField0, "Verdana", 10, Font.PLAIN);
        _nsTextField0.setEditable(false);
        _nsTextField0.setOpaque(false);
        _nsTextField0.setText("Connection Test");
        _nsTextField0.setHorizontalAlignment(javax.swing.JTextField.LEFT);
        _nsTextField0.setSelectable(false);
        _nsTextField0.setEnabled(true);
        _nsTextField0.setBorder(null);
    }
}