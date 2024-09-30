export default {
    multiple({data, headers}) {
        return data.response?.ffmpegservice_accounts.map((item) => {
            return item.ffmpegservice_account
        })
    },
    single({data, headers}) {
        return data.response?.ffmpegservice_account
    },
    startStreaming({data, headers}) {
        return data.response?.stream_preview?.ffmpegservice_account
    },
}