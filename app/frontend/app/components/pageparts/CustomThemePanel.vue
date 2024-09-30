<template>
    <div id="customThemePanel">
        <h2>Customization</h2>
        <h3>Themes:</h3>
        <m-select
            ref="selectTheme"
            :options="themesToOptions"
            @change="themeChange" />
        <m-btn
            :full="true"
            class="theme__save"
            @click="saveAsDefault">
            Enable this theme as default
        </m-btn>
        <hr>
        <h3>Colors:</h3>
        <m-accordion
            v-for="cat in categories"
            :key="cat"
            :title="cat">
            <div
                v-for="v in sortTheme(cat)"
                :key="v.id"
                class="theme__label">
                <span class="theme__name">{{ v.name }}</span>
                <div class="theme__inputs">
                    <input
                        :id="v.property"
                        v-model="v.value"
                        :name="v.property"
                        class="theme__color"
                        type="color"
                        @input="colorChange($event, v.property)">
                    <span class="theme__value">{{ v.value }}</span>
                    <div
                        :style="'background-color:' + v.value"
                        class="theme__color__view"
                        title="Color preview" />
                </div>
            </div>
        </m-accordion>

        <m-btn
            :full="true"
            class="theme__save"
            @click="saveCurrent">
            Save
        </m-btn>
        <m-btn
            :full="true"
            class="theme__save"
            @click="saveCurrentAndEnable">
            Save and Enable
        </m-btn>
        <m-btn
            :full="true"
            class="theme__save"
            type="bordered"
            @click="cancel">
            Cancel
        </m-btn>
    </div>
</template>

<script>
import Themes from "@models/Themes"

export default {
    data() {
        return {
            themesList: [],
            currentTheme: null,
            categories: [],
            selectedTheme: null
        }
    },
    computed: {
        themesToOptions() {
            return this.themesList.map(t => {
                return {
                    name: t.theme.name,
                    value: t.theme.id
                }
            })
        }
    },
    mounted() {
        this.$eventHub.$on("open-customization", () => {
            this.fetchThemes()
        })
    },
    methods: {
        sortTheme(group) {
            return this.currentTheme.variables.filter(t => t.group_name == group)
        },
        fetchThemes() {
            Themes.api().getThemes().then(res => {
                this.themesList = res.response.data.response.themes
                let cur = this.themesList.find(e => e.theme.is_default)?.theme
                this.$nextTick(() => {
                    this.$refs.selectTheme?.updateOption({
                        name: cur.name,
                        value: cur.id
                    })
                })
                let id = cur?.id
                if (!id) return
                this.getTheme(id)
            })
        },
        getTheme(id) {
            Themes.api().getTheme({id}).then(resT => {
                this.currentTheme = resT.response.data.response.theme
                this.categories = []
                this.currentTheme.variables.forEach(e => {
                    if (!this.categories.find(f => f === e.group_name)) this.categories.push(e.group_name)
                    document.documentElement.style.setProperty('--' + e.property, e.value)
                })
            })
        },
        themeChange(opt) {
            this.getTheme(opt)
        },
        colorChange(event, property) {
            document.documentElement.style.setProperty('--' + property, event.target.value)
        },
        saveAsDefault() {
            this.currentTheme.is_default = true
            Themes.api().updateTheme(this.currentTheme).then(res => {
                this.$flash('Default theme changed', 'success')
            })
        },
        saveCurrent() {
            this.currentTheme.system_theme_variables_attributes = this.currentTheme.variables
            Themes.api().updateTheme(this.currentTheme).then(res => {
                this.$flash('Saved', 'success')
            })
        },
        saveCurrentAndEnable() {
            this.currentTheme.system_theme_variables_attributes = this.currentTheme.variables
            this.currentTheme.is_default = true
            Themes.api().updateTheme(this.currentTheme).then(res => {
                this.$flash('Saved and Default theme changed', 'success')
            })
        },
        cancel() {
            this.getTheme(this.currentTheme.id)
            this.$flash('Return to default color settings', 'success')
        }
    }
}
</script>

