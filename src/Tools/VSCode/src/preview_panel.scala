/*  Title:      Tools/VSCode/src/preview_panel.scala
    Author:     Makarius

HTML document preview.
*/

package isabelle.vscode


import isabelle._

import java.io.{File => JFile}


class Preview_Panel(resources: VSCode_Resources)
{
  private val pending = Synchronized(Map.empty[JFile, Int])

  def request(file: JFile, column: Int): Unit =
    pending.change(map => map + (file -> column))

  def flush(channel: Channel): Boolean =
  {
    pending.change_result(map =>
    {
      val map1 =
        (map /: map.iterator)({ case (m, (file, column)) =>
          resources.get_model(file) match {
            case Some(model) =>
              val snapshot = model.snapshot()
              if (snapshot.is_outdated) m
              else {
                val context = Presentation.html_context()
                val document = Presentation.html_document(resources, snapshot, context)
                channel.write(LSP.Preview_Response(file, column, document.title, document.content))
                m - file
              }
            case None => m - file
          }
        })
      (map1.nonEmpty, map1)
    })
  }
}
