// The serviceworker context can respond to 'push' events and trigger
// notifications on the registration property
self.addEventListener("push", (event) => {
    const data = event.data.json()
    let title = data.title
    let body = data.body
    let tag = data.tag
    let icon = data.icon

    event.waitUntil(
        self.registration.showNotification(title, {
                body,
                icon,
                tag
            }
        )
    )
})
