import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import St from 'gi://St';
import Clutter from 'gi://Clutter';
import GObject from 'gi://GObject';

const RoxyButton = GObject.registerClass(
class RoxyButton extends St.Button {
    _init() {
        super._init({
            style_class: 'panel-button',
            reactive: true,
            can_focus: true,
            track_hover: true,
            y_align: Clutter.ActorAlign.CENTER,
        });

        const box = new St.BoxLayout({
            style_class: 'roxy-badge-box',
            y_align: Clutter.ActorAlign.CENTER,
        });

        // Glowing cyan dot
        const dot = new St.Widget({
            style_class: 'roxy-cyan-dot',
            y_align: Clutter.ActorAlign.CENTER,
        });
        box.add_child(dot);

        // RoxyOS label
        const label = new St.Label({
            text: 'RoxyOS',
            style_class: 'roxy-badge-label',
            y_align: Clutter.ActorAlign.CENTER,
        });
        box.add_child(label);

        this.set_child(box);

        this.connect('clicked', () => {
            Main.overview.toggle();
        });
    }
});

export default class RoxyBadgeExtension extends Extension {
    enable() {
        this._button = new RoxyButton();
        Main.panel.addToStatusArea('roxy-badge', this._button, 0, 'left');

        if (Main.panel.statusArea.activities) {
            Main.panel.statusArea.activities.container.hide();
        }
    }

    disable() {
        if (Main.panel.statusArea.activities) {
            Main.panel.statusArea.activities.container.show();
        }
        if (this._button) {
            this._button.destroy();
            this._button = null;
        }
    }
}
