/*  Title:      Pure/Admin/build_sqlite.scala
    Author:     Makarius

Build Isabelle sqlite-jdbc component from official download.
*/

package isabelle


object Build_SQLite {
  /* build sqlite */

  val default_download_url =
    "https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.39.4.1/sqlite-jdbc-3.39.4.1.jar"

  def build_sqlite(
    download_url: String = default_download_url,
    progress: Progress = new Progress,
    target_dir: Path = Path.current
  ): Unit = {
    val Download_Name = """^.*/([^/]+)\.jar""".r
    val download_name =
      download_url match {
        case Download_Name(download_name) => download_name
        case _ => error("Malformed jar download URL: " + quote(download_url))
      }


    /* component */

    val component_dir =
      Components.Directory(target_dir + Path.basic(download_name)).create(progress = progress)


    /* README */

    File.write(component_dir.README,
      "This is " + download_name + " from\n" + download_url +
        "\n\n        Makarius\n        " + Date.Format.date(Date.now()) + "\n")


    /* settings */

    component_dir.write_settings("""
ISABELLE_SQLITE_HOME="$COMPONENT"

classpath "$ISABELLE_SQLITE_HOME/lib/""" + download_name + """.jar"
""")


    /* jar */

    val jar = component_dir.lib + Path.basic(download_name).ext("jar")
    Isabelle_System.make_directory(jar.dir)
    Isabelle_System.download_file(download_url, jar, progress = progress)

    Isabelle_System.with_tmp_dir("build") { jar_dir =>
      Isabelle_System.extract(jar, jar_dir)

      val jar_files =
        List(
          "META-INF/maven/org.xerial/sqlite-jdbc/LICENSE" -> ".",
          "META-INF/maven/org.xerial/sqlite-jdbc/LICENSE.zentus" -> ".",
          "org/sqlite/native/Linux/aarch64/libsqlitejdbc.so" -> "arm64-linux",
          "org/sqlite/native/Linux/x86_64/libsqlitejdbc.so" -> "x86_64-linux",
          "org/sqlite/native/Mac/aarch64/libsqlitejdbc.jnilib" -> "arm64-darwin",
          "org/sqlite/native/Mac/x86_64/libsqlitejdbc.jnilib" -> "x86_64-darwin",
          "org/sqlite/native/Windows/x86_64/sqlitejdbc.dll" -> "x86_64-windows")

      for ((file, dir) <- jar_files) {
        val target = Isabelle_System.make_directory(component_dir.path + Path.explode(dir))
        Isabelle_System.copy_file(jar_dir + Path.explode(file), target)
      }

      File.set_executable(component_dir.path + Path.explode("x86_64-windows/sqlitejdbc.dll"), true)
    }
  }


  /* Isabelle tool wrapper */

  val isabelle_tool =
    Isabelle_Tool("build_sqlite", "build Isabelle sqlite-jdbc component from official download",
      Scala_Project.here,
      { args =>
        var target_dir = Path.current
        var download_url = default_download_url

        val getopts = Getopts("""
Usage: isabelle build_sqlite [OPTIONS] DOWNLOAD

  Options are:
    -D DIR       target directory (default ".")
    -U URL       download URL
                 (default: """" + default_download_url + """")

  Build sqlite-jdbc component from the specified download URL (JAR), see also
  https://github.com/xerial/sqlite-jdbc and
  https://oss.sonatype.org/content/repositories/releases/org/xerial/sqlite-jdbc
""",
          "D:" -> (arg => target_dir = Path.explode(arg)),
          "U:" -> (arg => download_url = arg))

        val more_args = getopts(args)
        if (more_args.nonEmpty) getopts.usage()

        val progress = new Console_Progress()

        build_sqlite(download_url = download_url, progress = progress, target_dir = target_dir)
      })
}
