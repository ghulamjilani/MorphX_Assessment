import Quill from 'quill';

const BlockEmbed = Quill.import('blots/block/embed');
class RegularMediaBlot extends BlockEmbed {
  static create(dataLink) {
    if(dataLink.toString().includes("HTMLDivElement")) return dataLink
    const node = super.create()
    var html = `
        <div
            class="morphx__embed embed__innerInsert"
            style="
              display: block;
              position: relative;
              padding-top: 56.25%;
        ">
          <iframe
              src="${dataLink}"
              class="morphx__embed__iframe"
              style="display: block !important;width: 100% !important;height: 100% !important;position: absolute  !important;left: 0 !important;top: 0 !important;"
              frameborder="0"
              allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              allowfullscreen></iframe>

        </div>`
    node.innerHTML = html
    return node
  }

  static value(node) {
    return node;
  }
}

RegularMediaBlot.blotName = 'regularEmbed';
RegularMediaBlot.tagName = 'div';

Quill.register(RegularMediaBlot);

export default RegularMediaBlot;