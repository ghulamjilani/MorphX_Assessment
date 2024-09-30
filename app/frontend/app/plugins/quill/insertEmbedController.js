import Session from "@models/Session"

/**
 * add
import MediaBlot from "@plugins/quill/insertEmbed"
Quill.register("modules/MediaBlot", MediaBlot)
import RegularMediaBlot from "@plugins/quill/insertRegularEmbed"
Quill.register("modules/RegularMediaBlot", RegularMediaBlot)
import insertEmbedController from "@plugins/quill/insertEmbedController"

* use like this:
insertEmbedController.insertEmbedLink(this.$refs.editor.quill, this.quillLastCaretPosition, this.embedLink).then(() => {
    this.embedLink = ''
    this.$refs.linkModal.closeModal()
})
 */

export default {
  insertEmbedLink: (quill, quillLastCaretPosition, embedLink) => {
    return new Promise((resolve, reject) => {
      let searchIdParams = ["video_id", "recording_id"]
      let link = new URL(embedLink)
      let type = "recording"

      if(link.origin == location.origin) {
          let id = searchIdParams.reduce((acc, param) => {
              if (link.searchParams.get(param)) {
                  acc = link.searchParams.get(param)
                  type = param == "video_id" ? "video" : "recording"
                }
                return acc
            }, null)
            console.log(type, id);
          if(!id) {
              Session.api().getSessionBySlug({
                  slug: link.pathname.slice(1).replaceAll("/", "%2F")
              }).then(res => {
                  let session = res.response.data.response.session
                  if(session) {
                      quill.insertEmbed(quillLastCaretPosition, 'customEmbed', {
                          url: embedLink,
                          type: 'session',
                          session: session
                      })
                      resolve()
                  }
                  else {
                    quill.insertEmbed(quillLastCaretPosition, 'customEmbed', {
                        url: embedLink,
                        type: type
                    })
                    resolve()
                }
              })
          }
          else {
              quill.insertEmbed(quillLastCaretPosition, 'customEmbed', {
                  url: embedLink,
                  type: type
              })
              resolve()
          }
      }

      else if(link.origin.includes("youtube.com") || link.origin.includes("youtu.be"))
      {
          let id = link.searchParams.get("v")
          if(!id) {
              id = link.pathname.slice(1)
          }
          if(id) {
              let ytUrl = `https://www.youtube.com/embed/${id}`
              quill.insertEmbed(quillLastCaretPosition, 'regularEmbed', ytUrl)
              resolve()
          }
          else {
              quill.insertEmbed(quillLastCaretPosition, 'regularEmbed', embedLink)
              resolve()
          }
      }

      else if( link.origin.includes("vimeo.com") ) {
          let vmUrl = `https://player.vimeo.com/video/${link.pathname.slice(1)}`
          quill.insertEmbed(quillLastCaretPosition, 'regularEmbed', vmUrl)
          resolve()
      }
      else {
          quill.insertEmbed(quillLastCaretPosition, 'regularEmbed', embedLink)
          resolve()
      }
    })
  }
}