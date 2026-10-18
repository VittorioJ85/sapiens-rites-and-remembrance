local mod={loadOrder=25}
function mod:onload(ui)
    local derive=ui.createDerivedTreeDependencies
    function ui:createDerivedTreeDependencies(...)
        local skill=mjrequire "common/skill"
        for _,column in ipairs(self.skillUIColumns) do
            for _,entry in ipairs(column) do
                if entry.skillTypeIndex==skill.types.rrRemembrance.index then return derive(self,...) end
            end
        end
        for x,column in ipairs(self.skillUIColumns) do
            for y,entry in ipairs(column) do
                if entry.skillTypeIndex==skill.types.digging.index then
                    local target=self.skillUIColumns[x+1]
                    if not target then target={};self.skillUIColumns[x+1]=target end
                    local row=y
                    while target[row] and target[row].skillTypeIndex do row=row+1 end
                    for n=1,row do target[n]=target[n] or {} end
                    target[row]={skillTypeIndex=skill.types.rrRemembrance.index,
                        requiredSkillTypes={skill.types.digging.index}}
                    return derive(self,...)
                end
            end
        end
        return derive(self,...)
    end
end
return mod
