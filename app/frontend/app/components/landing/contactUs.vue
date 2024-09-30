<template>
    <div class="mf-contact">
        <a
            data-target="#ID-modal"
            data-toggle="modal">open modal</a>
        <div
            id="ID-modal"
            aria-hidden="true"
            class="modal fade"
            role="dialog">
            <div class="modal-dialog">
                <div class="modal-content">
                    <a
                        class="closeModal"
                        data="{dismiss: :modal}">{}
                        <i class="VideoClientIcon-iPlus" /></a>
                    <div class="modal-body">
                        <h4 class="groupTitle clearfix">
                            Modal Title
                        </h4>
                        <section>
                            Modal Content
                        </section>
                    </div>
                </div>
                <div class="text-right padding-top-10">
                    <a
                        class="btn btn-m"
                        data-dismiss="modal">close</a>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    name: "ContactUs"
}
</script>

