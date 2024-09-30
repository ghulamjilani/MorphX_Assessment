export default {
    data() {
        return {
            dragData: {
                el: undefined,
                container: undefined,
                body: document.body,
                active: false,
                currentX: 0,
                currentY: 0,
                initialX: 0,
                initialY: 0,
                xOffset: 0,
                yOffset: 0,
                axis: 'xy'
            }
        }
    },
    methods: {
        initDrag(el, container, startOffset, axix = 'x') {
            this.dragData.el = el;
            this.dragData.container = container;
            this.dragData.axix = axix;
            this.dragData.xOffset = startOffset.left;
            this.dragData.yOffset = startOffset.top;

            if (this.dragData.container) {
                this.dragData.container.addEventListener("touchstart", this.dragStart, false);
                this.dragData.container.addEventListener("touchmove", this.drag, false);

                this.dragData.container.addEventListener("mousedown", this.dragStart, false);
                this.dragData.container.addEventListener("mousemove", this.drag, false);
            }

            document.addEventListener("touchend", this.dragEnd, false);
            document.addEventListener("mouseup", this.dragEnd, false);
        },

        changeDragOffset(startOffset) {
            this.dragData.xOffset = startOffset.left;
            this.dragData.yOffset = startOffset.top;
        },

        dragStart(e) {
            this.dragData.body.style['user-select'] = 'none';
            if (e.type === "touchstart") {
                this.dragData.initialX = e.touches[0].clientX - this.dragData.xOffset;
                this.dragData.initialY = e.touches[0].clientY - this.dragData.yOffset;
            } else {
                this.dragData.initialX = e.clientX - this.dragData.xOffset;
                this.dragData.initialY = e.clientY - this.dragData.yOffset;
            }

            if (!this.trackProcessing) {
                this.dragData.active = true;
            }
        },

        dragEnd(e) {
            this.dragData.body.style['user-select'] = 'auto';
            this.dragData.initialX = this.dragData.currentX;
            this.dragData.initialY = this.dragData.currentY;

            this.dragData.active = false;
        },

        drag(e) {
            if (this.dragData.active) {

                e.preventDefault();

                if (e.type === "touchmove") {
                    this.dragData.currentX = e.touches[0].clientX - this.dragData.initialX;
                    this.dragData.currentY = e.touches[0].clientY - this.dragData.initialY;
                } else {
                    this.dragData.currentX = e.clientX - this.dragData.initialX;
                    this.dragData.currentY = e.clientY - this.dragData.initialY;
                }

                this.dragData.xOffset = this.dragData.currentX;
                this.dragData.yOffset = this.dragData.currentY;

                this.setTranslate(this.dragData.currentX, this.dragData.currentY);

                if (typeof this.dragCallback == 'function') {
                    this.dragCallback(this.dragData.currentX, this.dragData.currentY)
                }
            }
        },

        setTranslate(xPos, yPos) {
            if (this.dragData.axix == 'x') {
                this.dragData.el.style.transform = `translate(${xPos}px, 0)`;
            } else if (this.dragData.axix == 'y') {
                this.dragData.el.style.transform = `translate(0, ${yPos}px)`;
            } else {
                this.dragData.el.style.transform = `translate(${xPos}px, ${yPos}px)`;
            }
        }
    }
}