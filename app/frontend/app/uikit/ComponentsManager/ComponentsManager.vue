<template>
    <div class="componentsManager">
        <component-manager
            v-for="item in template.body.components"
            :key="item.key"
            :component-data="item"
            :group="group"
            :editing="editing"
            @orderChange="(val) => orderChange(item, val)"
            @remove="remove(item)" />

        <!-- v-if can -->
        <add-component
            v-if="editing"
            :group="group" />
        <div class="componentsManager__saveBtn">
            <m-btn
                v-if="editing"
                v-tooltip="'Save all Changes'"
                :loading="loading"
                type="save"
                :square="true"
                @click="saveTemplate">
                Save Changes
            </m-btn>
        </div>
    </div>
</template>

<script>
import PageBuilder from "@models/PageBuilder"

export default {
  name: "ComponentsManager",
  props: {
    group: {
      type: String,
      require: true
    },
    editingByDefault: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      editing: false,
      template: {
          body: {
            components: []
          }
      },
      //
      loading: false
    }
  },
  watch: {
    editing() {
      this.$eventHub.$emit("componentSettings:EditingChanged", this.editing)
    }
  },
  mounted() {
    this.getTemplate()

    window.saveTemplate = this.saveTemplate

    this.$eventHub.$on("componentSettings:toggleEditing", () => {
      this.editing = !this.editing
    })

    this.$eventHub.$on("componentSettings:switchEditing", (flag) => {
      this.editing = flag
    })

    this.$eventHub.$on("componentSettings:checkState", () => {
      this.$eventHub.$emit("componentSettings:EditingChanged", this.editing)
    })

    this.editing = this.editingByDefault

    this.$eventHub.$on("componentSettings:add", (group, settings) => {
      if(this.group == group) {
        settings.order = this.template.body.components.length
        settings.key = new Date().getTime()
        this.template.body.components.push(settings)
      }
    })
    this.$eventHub.$on("componentSettings:change", (group, settings) => {
      if(this.group == group) {
        let el = this.template.body.components.find(e => e.key == settings.key)
        el.type = settings.type
        el.props = settings.props
      }
    })

    this.fetchAds()
  },
  methods: {
    getTemplate() {
      let template = window.list_of_templates?.find(t => t.name === this.group)
      if(template) {
        this.template = template
        if(typeof this.template.body === String || typeof this.template.body == 'string') {
          this.template.body = JSON.parse(this.template.body)
        }
         this.sorting()
      }
      else {
        PageBuilder.api().fetchTemplateApi({name: this.group}).then(res => {
          this.template = res.response.data.response.system_template
          if(typeof this.template.body === String || typeof this.template.body == 'string') {
            this.template.body = JSON.parse(this.template.body)
          }
          this.sorting()
        }).catch(() => {
          this.template = {
            name: this.group,
            body: {
              components: []
            }
          }
        })
      }

    },
    saveTemplate() {
      this.loading = true
      PageBuilder.api().createTemplateApi({
        name: this.template.name,
        body: JSON.stringify(this.template.body)
        }).then(res => {
          this.loading = false
          this.$flash("Saved!", "success")
          console.log(res)
      })
    },
    orderChange(item, val) {
      let newOrder = item.order + val
      if(newOrder < this.template.body.components.length && newOrder >= 0) {
        this.template.body.components.find(e => e.order == newOrder).order = item.order
        item.order = newOrder
      }
      this.sorting()
    },
    sorting() {
      this.template.body.components.sort((a, b) => { return a.order - b.order })
    },
    remove(item) {
      this.template.body.components = this.template.body.components.filter(e => e.key != item.key)
      this.sorting()
      this.template.body.components?.forEach((t, i) => {
        t.order = i
      })
    },
     fetchAds() {
      PageBuilder.api().fetchAdvertisementBanners().then((res) => {
        this.$store.dispatch("Global/setAdvertisementBanners", res.response.data.response.ad_banners)
      })
    }
  }
}
</script>

<style>

</style>