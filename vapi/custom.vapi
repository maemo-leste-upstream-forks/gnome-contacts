namespace Gnome {
	[CCode (cheader_filename = "libgnome-desktop/gnome-desktop-thumbnail.h")]
	public class DesktopThumbnailFactory : GLib.Object {
		[CCode (has_construct_function = false)]
		public DesktopThumbnailFactory (Gnome.ThumbnailSize size);
		public bool can_thumbnail (string uri, string mime_type, ulong mtime);
		public void create_failed_thumbnail (string uri, ulong mtime);
		public unowned Gdk.Pixbuf generate_thumbnail (string uri, string mime_type);
		public bool has_valid_failed_thumbnail (string uri, ulong mtime);
		public unowned string lookup (string uri, ulong mtime);
		public void save_thumbnail (Gdk.Pixbuf thumbnail, string uri, ulong original_mtime);
	}
	[CCode (cheader_filename = "libgnome-desktop/gnome-desktop-thumbnail.h", cprefix = "GNOME_DESKTOP_THUMBNAIL_SIZE_")]
	public enum ThumbnailSize {
		NORMAL,
		LARGE
	}
}

[CCode (cprefix = "G", lower_case_cprefix = "g_", cheader_filename = "glib.h", gir_namespace = "GLib", gir_version = "2.0")]
namespace LocalGLib {
	[CCode (cname = "C_", cheader_filename = "glib.h,glib/gi18n-lib.h")]
	public static unowned string C_ (string contect, string str);
}