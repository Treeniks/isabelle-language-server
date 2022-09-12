/*  Title:      Pure/Admin/build_postgresql.scala
    Author:     Makarius

Build Isabelle postgresql component from official download.
*/

package isabelle


object Build_PostgreSQL {
  /* URLs */

  val notable_urls =
    List("https://jdbc.postgresql.org", "https://jdbc.postgresql.org/download.html")

  val default_download_url = "https://jdbc.postgresql.org/download/postgresql-42.5.0.jar"


  /* build postgresql */

  def build_postgresql(
    download_url: String = default_download_url,
    progress: Progress = new Progress,
    target_dir: Path = Path.current
  ): Unit = {
    /* name and version */

    def err(): Nothing = error("Malformed jar download URL: " + quote(download_url))

    val Name = """^.*/([^/]+)\.jar""".r
    val download_name = download_url match { case Name(name) => name case _ => err() }
 
    val Version = """^.[^0-9]*([0-9].*)$""".r
    val download_version = download_name match { case Version(version) => version case _ => err() }


    /* component */

    val component_dir = Isabelle_System.new_directory(target_dir + Path.basic(download_name))
    progress.echo("Component " + component_dir)


    /* LICENSE */

    File.write(component_dir + Path.basic("LICENSE"),
"""Copyright (c) 1997, PostgreSQL Global Development Group
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
""")


    /* README */

    File.write(component_dir + Path.basic("README"),
"""This is PostgreSQL JDBC """ + download_version + """ from
""" + notable_urls.mkString(" and ") + """

        Makarius
        """ + Date.Format.date(Date.now()) + "\n")


    /* settings */

    val etc_dir = Isabelle_System.make_directory(component_dir + Path.basic("etc"))

    File.write(etc_dir + Path.basic("settings"),
"""# -*- shell-script -*- :mode=shellscript:

classpath "$COMPONENT/""" + download_name + """.jar"
""")


    /* jar */

    val jar = component_dir + Path.basic(download_name).ext("jar")
    Isabelle_System.download_file(download_url, jar, progress = progress)
  }


  /* Isabelle tool wrapper */

  val isabelle_tool =
    Isabelle_Tool("build_postgresql", "build Isabelle postgresql component from official download",
      Scala_Project.here,
      { args =>
        var target_dir = Path.current
        var download_url = default_download_url

        val getopts = Getopts("""
Usage: isabelle build_postgresql [OPTIONS]

  Options are:
    -D DIR       target directory (default ".")
    -U URL       download URL
                 (default: """" + default_download_url + """")

  Build postgresql component from the specified download URL (JAR), see also
  """ + notable_urls.mkString(" and "),
          "D:" -> (arg => target_dir = Path.explode(arg)),
          "U:" -> (arg => download_url = arg))

        val more_args = getopts(args)
        if (more_args.nonEmpty) getopts.usage()

        val progress = new Console_Progress()

        build_postgresql(download_url, progress = progress, target_dir = target_dir)
      })
}