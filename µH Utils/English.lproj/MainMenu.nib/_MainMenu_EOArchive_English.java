// _MainMenu_EOArchive_English.java
// Generated by EnterpriseObjects palette at Monday, July 24, 2006 1:49:07 PM US/Pacific

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

public class _MainMenu_EOArchive_English extends com.webobjects.eoapplication.EOArchive {
    Controller _controller0;
    Downloader _downloader0;
    com.webobjects.eointerface.swing.EOFrame _eoFrame0;
    com.webobjects.eointerface.swing.EOTextField _nsTextField0, _nsTextField1, _nsTextField2, _nsTextField3;
    com.webobjects.eointerface.swing.EOView _nsBox0, _nsBox1, _nsProgressIndicator0, _nsView0;
    javax.swing.JButton _nsButton0, _nsButton1, _nsButton2;
    javax.swing.JComboBox _popup0;
    javax.swing.JPanel _nsView1;
    javax.swing.JTabbedPane _nsTabView0;

    public _MainMenu_EOArchive_English(Object owner, NSDisposableRegistry registry) {
        super(owner, registry);
    }

    protected void _construct() {
        Object owner = _owner();
        EOArchive._ObjectInstantiationDelegate delegate = (owner instanceof EOArchive._ObjectInstantiationDelegate) ? (EOArchive._ObjectInstantiationDelegate)owner : null;
        Object replacement;

        super._construct();

        _nsBox1 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "NSView");
        _nsBox0 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "NSBox1");
        _nsTextField3 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField1111111");
        _nsTextField2 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField111111");
        _nsView0 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "NSView");
        _nsTabView0 = (javax.swing.JTabbedPane)_registered(new javax.swing.JTabbedPane(), "NSTabView");
        _nsTextField1 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField1111112");
        _nsButton2 = (javax.swing.JButton)_registered(new javax.swing.JButton("Manual Download"), "");
        _nsTextField0 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField1111112");
        _nsProgressIndicator0 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "1");
        _downloader0 = (Downloader)_registered(new Downloader(), "Downloader");
        _nsButton1 = (javax.swing.JButton)_registered(new javax.swing.JButton("Download"), "");
        _nsButton0 = (javax.swing.JButton)_registered(new javax.swing.JButton("Connect"), "");
        _controller0 = (Controller)_registered(new Controller(), "Controller");
        _popup0 = (javax.swing.JComboBox)_registered(new javax.swing.JComboBox(), "NSPopUpButton");
        _eoFrame0 = (com.webobjects.eointerface.swing.EOFrame)_registered(new com.webobjects.eointerface.swing.EOFrame(), "Window");
        _nsView1 = (JPanel)_eoFrame0.getContentPane();
    }

    protected void _awaken() {
        super._awaken();
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "hide", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "hideOtherApplications", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "orderFrontStandardAboutPanel", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "terminate", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "unhideAllApplications", ), ""));
        _popup0.setModel(new javax.swing.DefaultComboBoxModel());
        _popup0.addItem(" ");
    }

    protected void _init() {
        super._init();
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "cut", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "performFindPanelAction", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "selectAll", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "paste", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "toggleContinuousSpellChecking", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "performZoom", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "redo", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "copy", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "delete", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "clearRecentDocuments", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "undo", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "runPageLayout", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "performFindPanelAction", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "performFindPanelAction", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "performClose", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "checkSpelling", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "pasteAsPlainText", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "performFindPanelAction", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "centerSelectionInVisibleArea", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "showGuessPanel", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "performMiniaturize", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "arrangeInFront", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "print", ), ""));
        .addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(null, "showHelp", ), ""));
        if (!(_nsBox0.getLayout() instanceof EOViewLayout)) { _nsBox0.setLayout(new EOViewLayout()); }
        _nsBox1.setSize(125, 1);
        _nsBox1.setLocation(2, 2);
        ((EOViewLayout)_nsBox0.getLayout()).setAutosizingMask(_nsBox1, EOViewLayout.MinYMargin);
        _nsBox0.add(_nsBox1);
        _nsBox0.setBorder(new com.webobjects.eointerface.swing._EODefaultBorder("", true, "Lucida Grande", 13, Font.PLAIN));
        _setFontForComponent(_nsTextField3, "Lucida Grande", 10, Font.PLAIN);
        _nsTextField3.setEditable(false);
        _nsTextField3.setOpaque(false);
        _nsTextField3.setText("\"Manual\" download if keyer not responding:");
        _nsTextField3.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField3.setSelectable(false);
        _nsTextField3.setEnabled(true);
        _nsTextField3.setBorder(null);
        _setFontForComponent(_nsTextField2, "Lucida Grande", 10, Font.PLAIN);
        _nsTextField2.setEditable(false);
        _nsTextField2.setOpaque(false);
        _nsTextField2.setText("Normal download:");
        _nsTextField2.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField2.setSelectable(false);
        _nsTextField2.setEnabled(true);
        _nsTextField2.setBorder(null);
        if (!(_nsView0.getLayout() instanceof EOViewLayout)) { _nsView0.setLayout(new EOViewLayout()); }
        _nsButton1.setSize(68, 20);
        _nsButton1.setLocation(170, 34);
        ((EOViewLayout)_nsView0.getLayout()).setAutosizingMask(_nsButton1, EOViewLayout.MinYMargin);
        _nsView0.add(_nsButton1);
        _nsButton2.setSize(116, 20);
        _nsButton2.setLocation(285, 80);
        ((EOViewLayout)_nsView0.getLayout()).setAutosizingMask(_nsButton2, EOViewLayout.MinYMargin);
        _nsView0.add(_nsButton2);
        _nsTextField2.setSize(111, 13);
        _nsTextField2.setLocation(52, 37);
        ((EOViewLayout)_nsView0.getLayout()).setAutosizingMask(_nsTextField2, EOViewLayout.MinYMargin);
        _nsView0.add(_nsTextField2);
        _nsTextField3.setSize(234, 13);
        _nsTextField3.setLocation(44, 83);
        ((EOViewLayout)_nsView0.getLayout()).setAutosizingMask(_nsTextField3, EOViewLayout.MinYMargin);
        _nsView0.add(_nsTextField3);
        _nsProgressIndicator0.setSize(120, 12);
        _nsProgressIndicator0.setLocation(255, 39);
        ((EOViewLayout)_nsView0.getLayout()).setAutosizingMask(_nsProgressIndicator0, EOViewLayout.MinYMargin);
        _nsView0.add(_nsProgressIndicator0);
        _nsTextField0.setSize(42, 13);
        _nsTextField0.setLocation(380, 39);
        ((EOViewLayout)_nsView0.getLayout()).setAutosizingMask(_nsTextField0, EOViewLayout.MinYMargin);
        _nsView0.add(_nsTextField0);
        _nsTabView0.addTab("Firmware Download", _nsView0);
        _connect(_controller0, _eoFrame0, "window");
        _setFontForComponent(_nsTextField1, "Lucida Grande", 12, Font.PLAIN);
        _nsTextField1.setEditable(false);
        _nsTextField1.setOpaque(false);
        _nsTextField1.setText("");
        _nsTextField1.setHorizontalAlignment(javax.swing.JTextField.LEFT);
        _nsTextField1.setSelectable(false);
        _nsTextField1.setEnabled(true);
        _nsTextField1.setBorder(null);
        _connect(_controller0, _nsTextField1, "versionField");
        _setFontForComponent(_nsButton2, "Lucida Grande", 11, Font.PLAIN);
        _nsButton2.setMargin(new Insets(0, 2, 0, 2));
        _connect(_controller0, _nsButton2, "autoloadButton");
        _setFontForComponent(_nsTextField0, "Lucida Grande", 10, Font.PLAIN);
        _nsTextField0.setEditable(false);
        _nsTextField0.setOpaque(false);
        _nsTextField0.setText("");
        _nsTextField0.setHorizontalAlignment(javax.swing.JTextField.LEFT);
        _nsTextField0.setSelectable(false);
        _nsTextField0.setEnabled(true);
        _nsTextField0.setBorder(null);
        _connect(_downloader0, _nsTextField0, "progressField");
        _connect(_downloader0, _nsProgressIndicator0, "progressBar");
        _connect(_controller0, _downloader0, "downloader");
        _setFontForComponent(_nsButton1, "Lucida Grande", 11, Font.PLAIN);
        _nsButton1.setMargin(new Insets(0, 2, 0, 2));
        _connect(_controller0, _nsButton1, "downloadButton");
        _setFontForComponent(_nsButton0, "Lucida Grande", 11, Font.PLAIN);
        _nsButton0.setMargin(new Insets(0, 2, 0, 2));
        _connect(_controller0, _nsButton0, "connectButton");
        _connect(_controller0, _popup0, "deviceMenu");
        _setFontForComponent(_popup0, "Lucida Grande", 11, Font.PLAIN);
        if (!(_nsView1.getLayout() instanceof EOViewLayout)) { _nsView1.setLayout(new EOViewLayout()); }
        _popup0.setSize(123, 22);
        _popup0.setLocation(41, 20);
        ((EOViewLayout)_nsView1.getLayout()).setAutosizingMask(_popup0, EOViewLayout.MinYMargin);
        _nsView1.add(_popup0);
        _nsTabView0.setSize(519, 232);
        _nsTabView0.setLocation(-26, 110);
        ((EOViewLayout)_nsView1.getLayout()).setAutosizingMask(_nsTabView0, EOViewLayout.MinYMargin);
        _nsView1.add(_nsTabView0);
        _nsButton0.setSize(76, 20);
        _nsButton0.setLocation(343, 21);
        ((EOViewLayout)_nsView1.getLayout()).setAutosizingMask(_nsButton0, EOViewLayout.MinYMargin);
        _nsView1.add(_nsButton0);
        _nsBox0.setSize(433, 5);
        _nsBox0.setLocation(29, 54);
        ((EOViewLayout)_nsView1.getLayout()).setAutosizingMask(_nsBox0, EOViewLayout.MinYMargin);
        _nsView1.add(_nsBox0);
        _nsTextField1.setSize(327, 16);
        _nsTextField1.setLocation(40, 71);
        ((EOViewLayout)_nsView1.getLayout()).setAutosizingMask(_nsTextField1, EOViewLayout.MinYMargin);
        _nsView1.add(_nsTextField1);
        _nsView1.setSize(467, 264);
        _eoFrame0.setTitle("\u00b5H Utils");
        _eoFrame0.setLocation(691, 145);
        _eoFrame0.setSize(467, 264);
    }
}
