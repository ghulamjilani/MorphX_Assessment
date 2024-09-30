
export default {
    fetch(data) {
        let formatedConversation = data.conversation

        if(data.channel) {
            formatedConversation.channel = data.channel
        }


        return formatedConversation
    }
}