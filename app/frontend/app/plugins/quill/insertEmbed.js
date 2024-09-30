import Quill from 'quill';

const BlockEmbed = Quill.import('blots/block/embed');
class MediaBlot extends BlockEmbed {
  static create(data) {
    if(data.toString().includes("HTMLDivElement")) return data
    let link = new URL(data.url)
    let type = data.type
    let searchIdParams = ["video_id", "recording_id"]
    let id = searchIdParams.reduce((acc, param) => {
      if (link.searchParams.get(param)) {
        acc = link.searchParams.get(param)
      }
      return acc
    }, null)
    if(type === "session" && !id) {
      id = data.session.id
    }
    const node = super.create();
    var html = `<div class="morphx__embed embed__innerInsert" style="
            display: block;
            position: relative;
            padding-top: calc(56.25% + 102px);
        ">
            <iframe  src="${link.origin}/widgets/${id}/${type}/embedv2?options=${type == 'session' ? 'live' : ''}" class="morphx__embed__iframe"
                style="display: block !important;width: 100% !important;height: 100% !important;position: absolute  !important;left: 0 !important;top: 0 !important;" allow="encrypted-media" allowfullscreen=""
                frameborder="0" name=""></iframe>
        </div>`
    node.innerHTML = html;
    return node;
  }

  static value(node) {
    return node;
  }
}

MediaBlot.blotName = 'customEmbed';
MediaBlot.tagName = 'div';

Quill.register(MediaBlot);

export default MediaBlot;