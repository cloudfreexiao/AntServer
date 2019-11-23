local actions = {}

function actions.updateTitle(title)
    return {
        type = 'TEST1_UPDATE_TITLE',
        title = title
    }
end

function actions.updateUrl(url)
    return {
        type = 'TEST1_UPDATE_URL',
        url = url
    }
end

function actions.updateNum(num)
    return {
        type = 'TEST1_UPDATE_NUM',
        num = num
    }
end

function actions.updateFlag(flag)
    return {
        type = 'TEST1_UPDATE_FLAG',
        flag = flag
    }
end

function actions.done()
    return {
        type = 'TEST1_DONE'
    }
end

return actions

