/*  Title:      Pure/Admin/other_isabelle.scala
    Author:     Makarius

Manage other Isabelle distributions: support historic versions starting from
tag "build_history_base".
*/

package isabelle


object Other_Isabelle {
  def apply(
    isabelle_home: Path,
    isabelle_identifier: String = "",
    progress: Progress = new Progress
  ): Other_Isabelle = {
    if (proper_string(System.getenv("ISABELLE_SETTINGS_PRESENT")).isDefined) {
      error("Cannot initialize with enclosing ISABELLE_SETTINGS_PRESENT")
    }

    new Other_Isabelle(isabelle_home.canonical, isabelle_identifier, progress)
  }
}

final class Other_Isabelle private(
  val isabelle_home: Path,
  val isabelle_identifier: String,
  progress: Progress
) {
  override def toString: String = isabelle_home.toString


  /* static system */

  def bash(
    script: String,
    redirect: Boolean = false,
    echo: Boolean = false,
    strict: Boolean = true
  ): Process_Result = {
    progress.bash(
      Isabelle_System.export_isabelle_identifier(isabelle_identifier) + script,
      env = null, cwd = isabelle_home.file, redirect = redirect, echo = echo, strict = strict)
  }

  def getenv(name: String): String =
    bash("bin/isabelle getenv -b " + Bash.string(name)).check.out

  val settings: Isabelle_System.Settings = (name: String) => getenv(name)

  def expand_path(path: Path): Path = path.expand_env(settings)
  def bash_path(path: Path): String = Bash.string(expand_path(path).implode)

  val isabelle_home_user: Path = expand_path(Path.explode("$ISABELLE_HOME_USER"))

  def etc: Path = isabelle_home_user + Path.explode("etc")
  def etc_settings: Path = etc + Path.explode("settings")
  def etc_preferences: Path = etc + Path.explode("preferences")

  def resolve_components(echo: Boolean = false): Unit = {
    val missing = Path.split(getenv("ISABELLE_COMPONENTS_MISSING"))
    for (path <- missing) {
      Components.resolve(path.dir, path.file_name,
        progress = if (echo) progress else new Progress)
    }
  }

  def scala_build(fresh: Boolean = false, echo: Boolean = false): Unit = {
    if (fresh) {
      Isabelle_System.rm_tree(isabelle_home + Path.explode("lib/classes"))
    }

    val dummy_stty = Path.explode("~~/lib/dummy_stty/stty")
    if (!expand_path(dummy_stty).is_file) {
      Isabelle_System.copy_file(dummy_stty,
        Isabelle_System.make_directory(expand_path(dummy_stty.dir)))
    }
    try {
      bash(
        "export PATH=\"" + bash_path(dummy_stty.dir) + ":$PATH\"\n" +
        "export CLASSPATH=" + Bash.string(getenv("ISABELLE_CLASSPATH")) + "\n" +
        "bin/isabelle jedit -b", echo = echo).check
    }
    catch { case ERROR(msg) => cat_error("Failed to build Isabelle/Scala/Java modules:", msg) }
  }


  /* components */

  def init_components(
    component_repository: String = Components.default_component_repository,
    catalogs: List[String] = Components.default_catalogs,
    components: List[String] = Nil
  ): List[String] = {
    val admin = Components.admin(Path.ISABELLE_HOME).implode
    val components_base = quote("${ISABELLE_COMPONENTS_BASE:-$USER_HOME/.isabelle/contrib}")

    ("ISABELLE_COMPONENT_REPOSITORY=" + Bash.string(component_repository)) ::
    catalogs.map(name => "init_components " + components_base + " " + quote(admin + "/" + name)) :::
    components.map(name => "init_component " + components_base + "/" + name)
  }


  /* settings */

  def clean_settings(): Boolean =
    if (!etc_settings.is_file) true
    else if (File.read(etc_settings).startsWith("# generated by Isabelle")) {
      etc_settings.file.delete
      true
    }
    else false

  def init_settings(settings: List[String]): Unit = {
    if (clean_settings()) {
      Isabelle_System.make_directory(etc_settings.dir)
      File.write(etc_settings,
        "# generated by Isabelle " + Date.now() + "\n" +
        "#-*- shell-script -*- :mode=shellscript:\n" +
        settings.mkString("\n", "\n", "\n"))
    }
    else error("Cannot proceed with existing user settings file: " + etc_settings)
  }


  /* cleanup */

  def cleanup(): Unit = {
    clean_settings()
    etc.file.delete
    isabelle_home_user.file.delete
  }
}
