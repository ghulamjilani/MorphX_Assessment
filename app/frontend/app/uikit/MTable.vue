<template>
    <div
        :class="[thTextAlignClass, tdTextAlignClass, thFontWeightClass, cellPaddingClass, tableCollapseClass, borderedClass]"
        class="m-table">
        <table>
            <!-- @slot slot for tale content thead, tbody, th, td -->
            <slot />
        </table>
    </div>
</template>

<script>
/**
 * @example ./docs/mtable.md
 * @displayName Table
 */
export default {
    name: "MTable",
    props: {
        /**
         * \<th\> - text align
         * @values left, center, right
         * @default left
         */
        thTextAlign: {
            type: String,
            default: 'left'
        },
        /**
         * \<th\> - font weight
         * @values bold, normal
         * @default normal
         */
        thFontWeight: {
            type: String,
            default: 'normal'
        },
        /**
         * \<td\> - text align
         * @values left, center, right
         * @default left
         */
        tdTextAlign: {
            type: String,
            default: 'left'
        },
        /**
         * \<th\>, \<td\> - padding
         * @values xs, s, m, l, xl, (0.1rem, 0.5rem, 1rem, 1.5rem, 2rem)
         * @default m
         */
        cellPadding: {
            type: String,
            default: 'm'
        },
        /**
         * Column width in % started from the left to the right.
         * To correct work all values in the array in sum should be equal 100
         * @default []
         */
        columnWidthProportion: {
            type: Array,
            default: () => []
        },
        /**
         * Min table width
         * @default none
         */
        minWidth: {
            type: String
        },
        /**
         * Set different headers for mobile version.
         * Accepts headers from \<th\> if this field is not set.
         * @default none
         */
        mobileHeaders: {
            type: Array
        },
        /**
         * Screen width at which the table switches to mobile view.
         * @values phone, tablet, none (640px, 991px)
         * @default tablet
         */
        tableCollapse: {
            type: String,
            default: 'tablet'
        },
        /**
         * Table borders
         * @values all, bottom, none
         * @default bottom
         */
        bordered: {
            type: String,
            default: 'bottom'
        }
    },
    computed: {
        thTextAlignClass() {
            return `m-table__th__${this.thTextAlign}`
        },
        thFontWeightClass() {
            return `m-table__th__fontWeight__${this.thFontWeight}`
        },
        tdTextAlignClass() {
            return `m-table__td__${this.tdTextAlign}`
        },
        cellPaddingClass() {
            return `m-table__cell__padding__${this.cellPadding}`
        },
        tableCollapseClass() {
            return this.tableCollapse === 'none' ? '' : `m-table__collapse__${this.tableCollapse}`
        },
        borderedClass() {
            return this.bordered === 'none' ? '' : `m-table__bordered__${this.bordered}`
        }
    },
    mounted() {
        this.applyInitProps()
    },
    methods: {
        applyColumnWidthProportion() {
            if (this.columnWidthProportion && this.$el) {
                [...this.$el.getElementsByTagName('th')].forEach((th, index) => {
                    if (this.columnWidthProportion[index]) {
                        th.style.width = this.columnWidthProportion[index] + '%'
                    }
                })
            }
        },
        applyMinWidth() {
            if (this.minWidth) {
                this.$el.getElementsByTagName('table')[0].style.minWidth = this.minWidth
            }
        },
        applyMobileHeaders() {
            if (this.mobileHeaders) {
                this.mobileHeaders.forEach((header, index) => {
                    this._applyMobileHeaders(header, index)
                })
            } else {
                [...this.$el.getElementsByTagName('th')].forEach((th, index) => {
                    this._applyMobileHeaders(th.textContent, index)
                })
            }
        },
        _applyMobileHeaders(text, index) {
            [...this.$el.querySelectorAll(`tr > td:nth-child(${index + 1})`)].forEach((td) => {
                td.setAttribute('data-th', text)
            })
        },
        applyInitProps() {
            this.applyColumnWidthProportion()
            this.applyMinWidth()
            this.applyMobileHeaders()
        }
    }
}
</script>