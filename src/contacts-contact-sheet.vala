/*
 * Copyright (C) 2011 Alexander Larsson <alexl@redhat.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;
using Folks;
using Gee;

/**
 * The contact sheet displays the actual information of a contact.
 *
 * (Note: to edit a contact, use the {@link ContactEditor} instead.
 */
public class Contacts.ContactSheet : ContactForm {

  public ContactSheet (Contact contact, Store store) {
      this.contact = contact;
      this.store = store;

      this.contact.changed.connect (update);
      this.contact.individual.personas_changed.connect (update);
      this.store.quiescent.connect (update);

      update ();
  }

  private Button add_row_with_button (string label, string value, bool use_link_button = false) {
    var type_label = new Label (label);
    type_label.xalign = 1.0f;
    type_label.set_halign (Align.END);
    type_label.get_style_context ().add_class ("dim-label");
    this.container_grid.attach (type_label, 0, this.last_row);

    var value_button = use_link_button? new LinkButton (value) : new Button.with_label (value);
    value_button.focus_on_click = false;
    value_button.relief = ReliefStyle.NONE;
    value_button.halign = Align.START;
    this.container_grid.attach (value_button, 1, this.last_row);
    this.last_row++;

    (value_button.get_child () as Label).set_ellipsize (Pango.EllipsizeMode.END);
    (value_button.get_child () as Label).wrap_mode = Pango.WrapMode.CHAR;

    return value_button;
  }

  void add_row_with_label (string label_value,
                           string value,
                           Gtk.Widget? btn1 = null,
                           Gtk.Widget? btn2 =null) {
    if (value == "" || value == null)
      return;

    var type_label = new Label (label_value);
    type_label.xalign = 1.0f;
    type_label.set_halign (Align.END);
    type_label.set_valign (Align.START);
    type_label.get_style_context ().add_class ("dim-label");
    this.container_grid.attach (type_label, 0, this.last_row, 1, 1);

    var value_label = new Label (value);
    value_label.set_line_wrap (true);
    value_label.xalign = 0.0f;
    value_label.set_halign (Align.START);
    value_label.set_ellipsize (Pango.EllipsizeMode.END);
    value_label.wrap_mode = Pango.WrapMode.CHAR;
    value_label.set_selectable (true);

    /* FIXME: hardcode gap to match the button size */
    type_label.margin_top = 3;
    value_label.margin_start = 6;
    value_label.margin_top = 3;
    value_label.margin_bottom = 3;

    if (btn1 != null || btn2 !=null) {
      var value_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
      value_box.pack_start (value_label, false, false, 0);

      if (btn1 != null)
        value_box.pack_end (btn1, false, false, 0);
      if (btn2 != null)
        value_box.pack_end (btn2, false, false, 0);
      this.container_grid.attach (value_box, 1, this.last_row, 1, 1);
    } else {
      this.container_grid.attach (value_label, 1, this.last_row, 1, 1);
    }
    this.last_row++;
  }


  private void update () {
    this.last_row = 0;
    this.container_grid.foreach ((child) => this.container_grid.remove (child));

    var image_frame = new Avatar (PROFILE_SIZE, this.contact);
    image_frame.set_vexpand (false);
    image_frame.set_valign (Align.START);
    this.container_grid.attach (image_frame,  0, 0, 1, 3);

    create_name_label ();

    this.last_row += 3; // Name/Avatar takes up 3 rows

    var personas = this.contact.get_personas_for_display ();
    /* Cause personas are sorted properly I can do this */
    foreach (var p in personas) {
      bool is_first_persona = (this.last_row == 3);
      int persona_store_pos = this.last_row;
      if (!is_first_persona) {
        this.container_grid.attach (create_persona_store_label (p), 0, this.last_row, 3);
        this.last_row++;
      }

      foreach (var prop in ContactForm.SORTED_PROPERTIES)
        add_row_for_property (p, prop);

      // Nothing to show in the persona: don't mention it
      bool is_empty_persona = (this.last_row == persona_store_pos + 1);
      if (!is_first_persona && is_empty_persona) {
        this.container_grid.remove_row (persona_store_pos);
        this.last_row--;
      }
    }

    show_all ();
  }

  private void create_name_label () {
    var name_label = new Label ("");
    name_label.ellipsize = Pango.EllipsizeMode.END;
    name_label.xalign = 0f;
    name_label.selectable = true;
    this.container_grid.attach (name_label,  1, 0, 1, 3);
    this.contact.keep_widget_uptodate (name_label, (w) => {
        name_label.set_markup (Markup.printf_escaped ("<span font='16'>%s</span>",
                                                      this.contact.individual.display_name));
      });
  }

  private void add_row_for_property (Persona persona, string property) {
    switch (property) {
      case "email-addresses":
        add_emails (persona);
        break;
      case "phone-numbers":
        add_phone_nrs (persona);
        break;
      case "im-addresses":
        add_im_addresses (persona);
        break;
      case "urls":
        add_urls (persona);
        break;
      case "nickname":
        add_nickname (persona);
        break;
      case "birthday":
        add_birthday (persona);
        break;
      case "notes":
        add_notes (persona);
        break;
      case "postal-addresses":
        add_postal_addresses (persona);
        break;
      default:
        debug ("Unsupported property: %s", property);
        break;
    }
  }

  private void add_emails (Persona persona) {
    var details = persona as EmailDetails;
    if (details != null) {
      var emails = Contact.sort_fields<EmailFieldDetails>(details.email_addresses);
      foreach (var email in emails) {
          var button = add_row_with_button (TypeSet.email.format_type (email), email.value);
          button.clicked.connect (() => {
          Utils.compose_mail ("%s <%s>".printf(this.contact.individual.display_name, email.value));
        });
      }
    }
  }

  private Gtk.Button create_button (string icon) {
    var button = new Gtk.Button.from_icon_name (icon, Gtk.IconSize.BUTTON);
    button.set_halign (Gtk.Align.END);
    button.get_style_context ().add_class ("flatten");

    return button;
  }


  private void add_phone_nrs (Persona persona) {
    var phone_details = persona as PhoneDetails;
    if (phone_details != null) {
      var phones = Contact.sort_fields<PhoneFieldDetails>(phone_details.phone_numbers);
      foreach (var phone in phones) {
#if HAVE_TELEPATHY
        if (this.store.caller_account != null) {
          var button = add_row_with_button (TypeSet.phone.format_type (phone), phone.value);
          button.clicked.connect (() => {
              Utils.start_call (phone.get_normalised (), this.store.caller_account);
            });
        } else {
          add_row_with_label (TypeSet.phone.format_type (phone), phone.value);
        }
#else
        // Show a call button when we have a hanlder for it
        Gtk.Button call_button = null;
        Gtk.Button sms_button = null;
        if (AppInfo.get_all_for_type ("x-scheme-handler/tel").length () > 0) {
          call_button = create_button ("call-start-symbolic");
          call_button.clicked.connect (() => {
            Utils.start_call (phone.get_normalised ());
          });
        }
        if (AppInfo.get_all_for_type ("x-scheme-handler/sms").length () > 0) {
          sms_button = create_button ("user-available-symbolic");
          sms_button.clicked.connect (() => {
            Utils.send_sms (phone.get_normalised ());
          });
        }

        add_row_with_label (TypeSet.phone.format_type (phone), phone.value, call_button, sms_button);
#endif
      }
    }
  }

  private void add_im_addresses (Persona persona) {
#if HAVE_TELEPATHY
    var im_details = persona as ImDetails;
    if (im_details != null) {
      foreach (var protocol in im_details.im_addresses.get_keys ()) {
        foreach (var id in im_details.im_addresses[protocol]) {
          if (persona is Tpf.Persona) {
            var button = add_row_with_button (ImService.get_display_name (protocol), id.value);
            button.clicked.connect (() => {
                var im_persona = this.contact.find_im_persona (protocol, id.value);
                if (im_persona != null) {
                  var type = im_persona.presence_type;
                  if (type != PresenceType.UNSET && type != PresenceType.ERROR &&
                      type != PresenceType.OFFLINE && type != PresenceType.UNKNOWN) {
                    Utils.start_chat (this.contact, protocol, id.value);
                  }
                }
              });
          }
        }
      }
    }
#endif
  }

  private void add_urls (Persona persona) {
    var url_details = persona as UrlDetails;
    if (url_details != null) {
      foreach (var url in url_details.urls)
        add_row_with_button (_("Website"), url.value, true);
    }
  }

  private void add_nickname (Persona persona) {
    var name_details = persona as NameDetails;
    if (name_details != null && is_set (name_details.nickname))
      add_row_with_label (_("Nickname"), name_details.nickname);
  }

  private void add_birthday (Persona persona) {
    var birthday_details = persona as BirthdayDetails;
    if (birthday_details != null && birthday_details.birthday != null)
      add_row_with_label (_("Birthday"), birthday_details.birthday.to_local ().format ("%x"));
  }

  private void add_notes (Persona persona) {
    var note_details = persona as NoteDetails;
    if (note_details != null) {
      foreach (var note in note_details.notes)
        add_row_with_label (_("Note"), note.value);
    }
  }

  private void add_postal_addresses (Persona persona) {
    var addr_details = persona as PostalAddressDetails;
    if (addr_details != null) {
      foreach (var addr in addr_details.postal_addresses) {
        var all_strs = string.joinv ("\n", Contact.format_address (addr.value));
        add_row_with_label (TypeSet.general.format_type (addr), all_strs);
      }
    }
  }
}
