local function createTemplate()
    return {
        test = 5
    }
end

type template = typeof(createTemplate())
export type type = template

return createTemplate
