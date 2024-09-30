$.validator.addMethod('product_url', (function (value, element) {
    return this.optional(element) || /^https?:\/\/[^\s]+$/.test(value)
}), 'Please enter a valid url address.')

$.validator.addMethod('price', (function (value, element) {
    return this.optional(element) || parseFloat(value.replace(/[^\d]+/, "")) >= 0
}), 'Please enter a valid price, eg. GBP 12.23, $23.9, €0,98')

$('.dashboard-lists').on('change', 'input.inputfile', function (e) {
    var container, file, reader
    container = $(e.target).parents('.product-image')
    file = e.target.files[0]
    if (file) {
        reader = new FileReader
        reader.onload = (function (_this) {
            return function (e) {
                var img
                img = new Image
                img.onload = function () {
                    $(container).attr('style', "background-image: url(" + img.src + ")")
                    $(container).find('[name*=remote_original_url]').remove()
                }
                return img.src = e.target.result
            }
        })(this)
        return reader.readAsDataURL(file)
    }
})

$('#search_by_url, #search_by_upc').on('ajax:before', function (e) {
    $(e.target).find('button').attr('disabled', true).addClass('disabled').text('Processing...')
}).on('ajax:complete', function (e) {
    $(e.target).find('button').removeAttr('disabled').removeClass('disabled').text('Fetch')
    $(e.target).find('.input-block input').val('')
    $(e.target).find('.input-block').addClass('state-clear')
})

window.ListForm = Backbone.View.extend({
    render: function () {
        this.$('form').validate({
            rules: {
                'list[name]': {
                    required: true,
                    minlength: 2,
                    maxlength: 250
                },
                'list[description]': {
                    maxlength: 500
                }
            },
            errorElement: "span",
            ignore: '',
            errorPlacement: function (error, element) {
                return error.appendTo(element.parents('.input-block').find('.errorContainerWrapp')).addClass('errorContainer')
            },
            highlight: function (element) {
                var wrapper
                wrapper = $(element).parents('.input-block')
                return wrapper.addClass('error').removeClass('valid')
            },
            unhighlight: function (element) {
                var wrapper
                wrapper = $(element).parents('.input-block')
                return wrapper.removeClass('error').addClass('valid')
            }
        })
    }
})

window.ProductForm = Backbone.View.extend({
    events: {
        'click .clear_form': 'clearForm'
    },

    render: function () {
        this.validator = this.$('form').validate({
            rules: {
                'product[title]': {
                    required: true,
                    minlength: 2,
                    maxlength: 250
                },
                'product[short_description]': {
                    minlength: 24,
                    maxlength: 500
                },
                'product[specifications]': {
                    maxlength: 255
                },
                'product[url]': {
                    required: true,
                    product_url: true,
                    maxlength: 2000
                },
                'product[description]': {
                    maxlength: 2000
                },
                'product[price]': {
                    price: true
                }
            },
            errorElement: "span",
            ignore: '',
            errorPlacement: function (error, element) {
                return error.appendTo(element.parents('.input-block, .priceSection').find('.errorContainerWrapp')).addClass('errorContainer')
            },
            highlight: function (element) {
                var wrapper
                wrapper = $(element).parents('.input-block, .priceSection')
                return wrapper.addClass('error').removeClass('valid')
            },
            unhighlight: function (element) {
                var wrapper
                wrapper = $(element).parents('.input-block, .priceSection')
                return wrapper.removeClass('error').addClass('valid')
            }
        })
    },

    clearForm: function (e) {
        e.preventDefault()
        this.validator.resetForm()
        this.$('form .input-block:not(.specs)').addClass('state-clear')
        this.$('form')[0].reset()
        this.$('form .product-image').attr('style', "background-image: url(" + (this.$('form .product-image').attr('default_image')) + ");")
    }
})
