<template>
    <div id="NetworkSalesReports">
        <div class="reports-filter">
            <reports-filter
                @updateSearch="fetch" />
        </div>

        <m-btn @click="generateCsv">
            {{ $t('frontend.app.components.reports.network_sales_reports.export_csv') }}
        </m-btn>

        <div class="reports-table-wrapper">
            <table class="reports-table">
                <thead>
                    <!-- <tr> -->
                    <th @click="sort('organization.name')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.organization') }}
                        <sorting-arrows
                            field="organization.name"
                            :sorting="sorting" />
                    </th>
                    <th @click="sort('channel.name')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.channel') }}
                        <sorting-arrows
                            field="channel.name"
                            :sorting="sorting" />
                    </th>
                    <th @click="sort('type')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.product_type') }}
                        <sorting-arrows
                            field="type"
                            :sorting="sorting" />
                    </th>

                    <th @click="sort('purchased_item.name')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.content') }}
                        <sorting-arrows
                            field="purchased_item.name"
                            :sorting="sorting" />
                    </th>
                    <th @click="sort('purchased_item.creator.name')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.creator') }}
                        <sorting-arrows
                            field="purchased_item.creator.name"
                            :sorting="sorting" />
                    </th>
                    <th @click="sort('cost')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.cost') }}
                        <sorting-arrows
                            field="cost"
                            :sorting="sorting" />
                    </th>
                    <th @click="sort('qty')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.number') }}
                        <sorting-arrows
                            field="qty"
                            :sorting="sorting" />
                    </th>
                    <th @click="sort('gross_income')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.gross_income') }}
                        <sorting-arrows
                            field="gross_income"
                            :sorting="sorting" />
                    </th>
                    <th @click="sort('commission')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.platform_comission') }}
                        <sorting-arrows
                            field="commission"
                            :sorting="sorting" />
                    </th>
                    <th @click="sort('income')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.income') }}
                        <sorting-arrows
                            field="income"
                            :sorting="sorting" />
                    </th>
                    <th @click="sort('refund')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.refund') }}
                        <sorting-arrows
                            field="refund"
                            :sorting="sorting" />
                    </th>
                    <th @click="sort('refund_system')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.refund_platform') }}
                        <sorting-arrows
                            field="refund_system"
                            :sorting="sorting" />
                    </th>
                    <th @click="sort('refund_creator')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.refund_owner') }}
                        <sorting-arrows
                            field="refund_creator"
                            :sorting="sorting" />
                    </th>
                    <th @click="sort('total')">
                        {{ $t('frontend.app.components.reports.network_sales_reports.owner_income') }}
                        <sorting-arrows
                            field="total"
                            :sorting="sorting" />
                    </th>
                    <!-- </tr> -->
                </thead>
                <tbody>
                    <tr
                        v-for="item in reportsList"
                        :key="item.id">
                        <td> {{ item.organization.name }} </td>
                        <td> {{ item.channel.name }} </td>
                        <td> {{ item.type }} </td>
                        <td> {{ item.purchased_item.name }} </td>
                        <td> {{ (item.purchased_item.creator || {}).name }} </td>
                        <td> {{ item.cost }} </td>
                        <td> {{ item.qty }} </td>
                        <td> {{ item.gross_income }} </td>
                        <td> {{ item.commission }} </td>
                        <td> {{ item.income }} </td>
                        <td> {{ item.refund }} </td>
                        <td> {{ item.refund_system }} </td>
                        <td> {{ item.refund_creator }} </td>
                        <td> {{ item.total }} </td>
                    </tr>
                    <tr class="total">
                        <td><b>{{ $t('frontend.app.components.reports.network_sales_reports.total') }}</b></td>

                        <td />
                        <td />
                        <td />
                        <td />
                        <td />
                        <td />

                        <td>{{ getTotal('gross_income') }}</td>
                        <td>{{ getTotal('commission') }}</td>
                        <td>{{ getTotal('income') }}</td>
                        <td>{{ getTotal('refund') }}</td>
                        <td>{{ getTotal('refund_system') }}</td>
                        <td>{{ getTotal('refund_creator') }}</td>
                        <td>{{ getTotal('total') }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<script>
import Reports from "@models/Reports"

import ReportsFilter from "./ReportsFilter.vue"
import SortingArrows from "./SortingArrows"

export default {
	name: "NetworkSalesReports",
    components: { ReportsFilter, SortingArrows },
	data(){
		return {
			list: [],
            sorting: {
                field: "",
                order: 1
            },
            filters: null
		}
	},
    computed: {
        reportsList() {
            return [...this.list].sort((a, b) => {
                return this.sorting.order * (this.separate(a, this.sorting.field) >
                    this.separate(b, this.sorting.field) ?  1 : -1)
            })
        }
    },
	mounted(){
		// this.fetch()
	},
	methods: {
		fetch(filters = {}){
            this.filters = filters
			Reports.api().fetch(filters).then(res => {
				this.list = res.response.data.response
			})
		},
        generateCsv() {
			// Reports.api().generateCsv(this.filters).then(res => {

                let data = ""
                data += this.$t('frontend.app.components.reports.network_sales_reports.organization') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.channel') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.product_type') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.content') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.creator') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.cost') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.number') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.gross_income') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.platform_comission') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.income') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.refund') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.refund_platform') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.refund_owner') + ","
                data += this.$t('frontend.app.components.reports.network_sales_reports.owner_income') + "\n"

                this.reportsList.forEach(item => {
                    data += item.organization.name + ","
                    data += item.channel.name + ","
                    data += item.type + ","
                    data += item.purchased_item.name + ","
                    data += item.purchased_item.creator?.name + ","
                    data += item.cost + ","
                    data += item.qty + ","
                    data += item.gross_income + ","
                    data += item.commission + ","
                    data += item.income + ","
                    data += item.refund + ","
                    data += item.refund_system + ","
                    data += item.refund_creator + ","
                    data += item.total + "\n"
                })

                data += this.$t('frontend.app.components.reports.network_sales_reports.total') + ","
                data += ",,,,,,"

                data += this.getTotal('gross_income') + ","
                data += this.getTotal('commission') + ","
                data += this.getTotal('income') + ","
                data += this.getTotal('refund') + ","
                data += this.getTotal('refund_system') + ","
                data += this.getTotal('refund_creator') + ","
                data += this.getTotal('total')


                let encodedUri = encodeURI("data:text/csv;charset=utf-8," + data)
                let link = document.createElement("a")
                link.setAttribute("href", encodedUri)
                link.setAttribute("download", "report.csv")
                document.body.appendChild(link) // Required for FF
                link.click()
			// })
        },
        getTotal(field) {
            return Math.floor(this.list.reduce((sum, e) => sum += this.separate(e, field), 0) * 100)/100 // hate js
        },
        sort(sortingField) {
            if(this.sorting.field == sortingField) this.sorting.order *= -1
            else this.sorting = {
                field: sortingField,
                order: 1
            }
        },
        separate(obj, keys) {
            let k = keys.split(".")
            let o = obj
            for(let i = 0; i < k.length; i++ ) {
              if (o) {
                o = o[k[i]]
              } else {
                o = ""
              }
            }
            return o
        }
	}
}
</script>
