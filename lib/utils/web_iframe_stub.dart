// fallback non-web: kita gak bisa buat iframe
class WebIframeFactory {
  static String? register(String url) {
    // return null artinya belum support iframe di platform ini
    return null;
  }
}
