# Note: Mutt has a large number of non-upstream patches available for
# it, some of which conflict with each other. These patches are also
# not kept up-to-date when new versions of mutt (occasionally) come
# out.
#
# To reduce Homebrew's maintenance burden, new patches are not being
# accepted for this formula. We would be very happy to see members of
# the mutt community maintain a more comprehesive tap with better
# support for patches.

class Mutt < Formula
  desc "Mongrel of mail user agents (part elm, pine, mush, mh, etc.)"
  homepage "http://www.mutt.org/"
  url "https://bitbucket.org/mutt/mutt/downloads/mutt-1.5.24.tar.gz"
  mirror "ftp://ftp.mutt.org/pub/mutt/mutt-1.5.24.tar.gz"
  sha256 "a292ca765ed7b19db4ac495938a3ef808a16193b7d623d65562bb8feb2b42200"

  head do
    url "http://dev.mutt.org/hg/mutt#default", :using => :hg

    resource "html" do
      url "http://dev.mutt.org/doc/manual.html", :using => :nounzip
    end
  end

  unless Tab.for_name("signing-party").with? "rename-pgpring"
    conflicts_with "signing-party",
      :because => "mutt installs a private copy of pgpring"
  end

  conflicts_with "tin",
    :because => "both install mmdf.5 and mbox.5 man pages"

  option "with-debug", "Build with debug option enabled"
  option "with-trash-patch", "Apply trash folder patch"
  option "with-indexcolor-patch", "Apply indexcolor patch"
  option "with-s-lang", "Build against slang instead of ncurses"
  option "with-ignore-thread-patch", "Apply ignore-thread patch"
  option "with-confirm-attachment-patch", "Apply confirm attachment patch"

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  depends_on "openssl"
  depends_on "tokyo-cabinet"
  depends_on "s-lang" => :optional
  depends_on "gpgme" => :optional

  if build.with? "trash-patch"
    patch do
      url "https://blog.x-way.org/stuff/mutt-1.5.24-trash_folder.diff"
      sha256 "985d7f6ae17e15e525b19e348b3a43e78177cea3b775434abcbe7d220bebe934"
    end
  end

  if build.with? "indexcolor-patch"
    patch do
      url "https://blog.x-way.org/stuff/mutt-1.5.24-indexcolor.diff"
      sha256 "96c3ab28e0cb03646fbb0357650628591efabb102596978d1b05960d0e511f33"
    end
  end

  # original source for this went missing, patch sourced from Arch at
  # https://aur.archlinux.org/packages/mutt-ignore-thread/
  if build.with? "ignore-thread-patch"
    patch do
      url "https://gist.githubusercontent.com/mistydemeo/5522742/raw/1439cc157ab673dc8061784829eea267cd736624/ignore-thread-1.5.21.patch"
      sha256 "7290e2a5ac12cbf89d615efa38c1ada3b454cb642ecaf520c26e47e7a1c926be"
    end
  end

  if build.with? "confirm-attachment-patch"
    patch do
      url "https://gist.githubusercontent.com/tlvince/5741641/raw/c926ca307dc97727c2bd88a84dcb0d7ac3bb4bf5/mutt-attach.patch"
      sha256 "da2c9e54a5426019b84837faef18cc51e174108f07dc7ec15968ca732880cb14"
    end
  end

  def install
    args = ["--disable-dependency-tracking",
            "--disable-warnings",
            "--prefix=#{prefix}",
            "--with-ssl=#{Formula["openssl"].opt_prefix}",
            "--with-sasl",
            "--with-gss",
            "--enable-imap",
            "--enable-smtp",
            "--enable-pop",
            "--enable-hcache",
            "--with-tokyocabinet",
            # This is just a trick to keep 'make install' from trying
            # to chgrp the mutt_dotlock file (which we can't do if
            # we're running as an unprivileged user)
            "--with-homespool=.mbox"]
    args << "--with-slang" if build.with? "s-lang"
    args << "--enable-gpgme" if build.with? "gpgme"

    if build.with? "debug"
      args << "--enable-debug"
    else
      args << "--disable-debug"
    end

    system "./prepare", *args
    system "make"
    system "make", "install"

    doc.install resource("html") if build.head?
  end

  test do
    system bin/"mutt", "-D"
  end
end
