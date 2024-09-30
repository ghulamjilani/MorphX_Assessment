<template>
    <div class="roleEdit">
        <div>
            <div
                :class="{'roleEdit__pageTitle__show': showMode}"
                class="roleEdit__pageTitle">
                User Management
            </div>
            <div class="roleEdit__lowerTitle">
                <div v-show="!showMode">
                    {{ newMode ? 'New' : 'Edit' }} Role
                </div>
                <div
                    :class="{'roleEdit__buttons__show': showMode}"
                    class="roleEdit__buttons roleEdit__buttons__top">
                    <m-btn
                        size="s"
                        type="bordered"
                        @click="back()">
                        {{ showMode ? 'Back' : 'Cancel' }}
                    </m-btn>
                    <m-btn
                        v-if="!showMode && updateMode"
                        :disabled="disabled"
                        size="s"
                        type="save"
                        @click="update()">
                        Save Role
                    </m-btn>
                    <m-btn
                        v-if="!showMode && !updateMode"
                        :disabled="disabled"
                        size="s"
                        type="save"
                        @click="create()">
                        Create Role
                    </m-btn>
                </div>
            </div>
        </div>
        <div class="roleEdit__section">
            <m-form
                v-if="!showMode"
                v-model="disabled">
                <m-input
                    v-model="newGroup.name"
                    :max-counter="80"
                    field-id="roleName"
                    label="Role name"
                    rules="required|min-length:6|max-length:80" />
                <m-input
                    v-model="newGroup.description"
                    :max-counter="180"
                    field-id="roleDesc"
                    label="Role description"
                    rules="required|min-length:6|max-length:180" />
            </m-form>
            <div v-else-if="group">
                {{ group.name }}
            </div>
        </div>
        <div
            v-if="categories && categories.length"
            class="roleEdit__section">
            <div
                v-for="(category, index) in categories"
                :key="category.id">
                <div
                    :class="{top: index == 0}"
                    class="roleEdit__section__title">
                    {{ category.name }}
                </div>

                <div
                    v-for="credential in category.credentials"
                    :key="credential.id"
                    class="roleEdit__section__item">
                    <div class="roleEdit__section__item__roleName">
                        <span>
                            {{ credential.name }}
                            <m-checkbox
                                v-if="!showMode"
                                v-model="credentialsChecked"
                                :val="credential.id" />
                        </span>
                    </div>
                    <div class="roleEdit__section__item__roleDesc">
                        {{ credential.description }}
                    </div>
                </div>
            </div>
        </div>
        <div class="roleEdit__buttons">
            <m-btn
                size="s"
                type="bordered"
                @click="back()">
                {{ showMode ? 'Back' : 'Cancel' }}
            </m-btn>
            <m-btn
                v-if="!showMode && updateMode"
                :disabled="disabled"
                size="s"
                type="save"
                @click="update()">
                Save Role
            </m-btn>
            <m-btn
                v-if="!showMode && !updateMode"
                :disabled="disabled"
                size="s"
                type="save"
                @click="create()">
                Create Role
            </m-btn>
        </div>
    </div>
</template>

<script>
import Credentials from "@models/Credentials"
import Groups from "@models/Groups"

export default {
    props: {
        mode: String
    },
    data() {
        return {
            credentials: [],
            credentialsChecked: [],
            disabled: false,
            newGroup: {
                id: null,
                name: "",
                system: false,
                enabled: true,
                description: "",
                code: "",
                color: this.getRandomRolor()
            }
        }
    },
    computed: {
        newMode() {
            return this.mode == 'new'
        },
        showMode() {
            return this.mode == 'show'
        },
        editMode() {
            return this.mode == 'edit'
        },
        updateMode() {
            return this.mode == 'update'
        },
        groupCredentials() {
            if (this.group) return this.group.credentials
            else return null
        },
        group() {
            return Groups.query().whereId(parseInt(this.$route.params.id)).first()
        },
        categories() {
            const flag = {}
            const uniq = []
            if (this.mergedCredential && this.mergedCredential.length) {
                this.mergedCredential.forEach(cr => {
                    var category = cr.category
                    if (flag[category.id] === undefined) {
                        category.credentials = []
                        uniq.push(category)
                        flag[category.id] = uniq.length - 1
                    }
                    uniq[flag[category.id]].credentials.push(cr)
                })
                return uniq
            } else {
                return null
            }
        },
        mergedCredential() {
            if (this.editMode && this.groupCredentials && this.groupCredentials.length) {
                this.groupCredentials.forEach(cr => {
                    let index = this.credentials.findIndex((c) => {
                        return c.id == cr.id
                    })
                    this.credentials[index] = cr
                })
                return this.credentials
            } else if (this.showMode) {
                return this.groupCredentials
            } else {
                return this.credentials
            }
        }
    },
    watch: {
        group: {
            handler(val) {
                if (val) {
                    if (this.editMode) {
                        this.newGroup.name = val.name + "(Duplicate)"
                        this.newGroup.description = val.description
                    }
                    if (this.updateMode) {
                        this.newGroup.name = val.name
                        this.newGroup.id = val.id
                        this.newGroup.description = val.description
                    }
                }
            },
            deep: true,
            immediate: true
        },
        groupCredentials: {
            handler(val) {
                if (val) {
                    var checked = []
                    val.forEach(r => {
                        checked.push(r.id)
                    })
                    this.credentialsChecked = this.credentialsChecked.concat(checked)
                }
            },
            deep: true,
            immediate: true
        }
    },
    mounted() {
        this.getAllCredentials()
    },
    methods: {
        getRandomInt(min, max) {
            min = Math.ceil(min)
            max = Math.floor(max)
            return Math.floor(Math.random() * (max - min)) + min
        },
        getRandomRolor() {
            const r = this.getRandomInt(50, 150)
            const g = this.getRandomInt(50, 150)
            const b = this.getRandomInt(50, 150)
            return this.rgbToHex(r, g, b)
        },
        componentToHex(c) {
            let hex = c.toString(16)
            return hex.length == 1 ? "0" + hex : hex
        },
        rgbToHex(r, g, b) {
            return "#" + this.componentToHex(r) + this.componentToHex(g) + this.componentToHex(b)
        },
        update() {
            if (!this.credentialsChecked.length) return this.$flash('At least 1 credentials has to be chosen')
            Groups.api().updateGroup({
                id: this.newGroup.id,
                name: this.newGroup.name,
                enabled: this.newGroup.enabled,
                description: this.newGroup.description,
                // color:            this.newGroup.color,
                credential_ids: this.credentialsChecked
            }).then(() => {
                Groups.update({
                    where: this.newGroup.id,
                    data: {
                        name: this.newGroup.name,
                        enabled: this.newGroup.enabled,
                        credential_ids: this.credentialsChecked
                    }
                })
                this.$flash("Role has been updated", "success")
                this.$router.push({name: 'roles'})
            }).catch(error => {
                if (error?.response?.data?.message) {
                    if (typeof error.response.data.message == "string") {
                        this.$flash(error.response.data.message)
                    } else {
                        let message = error.response.data.message
                        let field = Object.keys(message)[0]
                        this.$flash(`Validation failed: ${field.charAt(0).toUpperCase() + field.slice(1)} ${message[field]}`)
                    }
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        },
        create() {
            if (!this.credentialsChecked.length) return this.$flash('At least 1 credentials has to be chosen')
            Groups.api().createGroup({
                name: this.newGroup.name,
                enabled: this.newGroup.enabled,
                description: this.newGroup.description,
                color: this.newGroup.color,
                credential_ids: this.credentialsChecked
            }).then(() => {
                this.$flash("Role has been created", "success")
                this.$router.push({name: 'roles'})
            }).catch(error => {
                if (error?.response?.data?.message) {
                    if (typeof error.response.data.message == "string") {
                        this.$flash(error.response.data.message)
                    } else {
                        let message = error.response.data.message
                        let field = Object.keys(message)[0]
                        this.$flash(`Validation failed: ${field.charAt(0).toUpperCase() + field.slice(1)} ${message[field]}`)
                    }
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        },
        back() {
            this.$router.go(-1)
        },
        getAllCredentials() {
            Credentials.api().allCredentials().then((res) => {
                this.credentials = res.response.data.response.credentials
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        }
    }
}
</script>