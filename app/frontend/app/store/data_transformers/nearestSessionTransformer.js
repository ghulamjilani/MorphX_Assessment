export default {
    single({data, headers}) {
        return data?.response?.session || {}
    },

    multiple({data, headers}) {
        throw  new Error('Add multiple data transformer to nearestSessionTransformer');
    }
}