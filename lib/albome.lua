local OOP = require("rmp.oop")

local Albome = OOP.class("Albome")
do
    function Albome:constructor(state, saved_path, error_color)
        self.plugin_state = state
        self.saved_path = saved_path
        self.error_color = error_color
    end

    function Albome:setSavedPath(saved_path)
        self.saved_path = saved_path
    end

    function Albome:setErrorColor(error_color)
        self.error_color = error_color
    end

    function Albome:save()
        local file = io.open(SAVED_PATH, "w")
        if not file then
            -- show_message("Error saving albums! path : " .. SAVED_PATH, ERROR_COLOR)
            return "Error saving albums! path : " .. self.saved_path, self.error_color
        end

        file:write("return {\n")
        for _, album in ipairs(self.plugin_state.albums) do
            file:write("  {\n")
            file:write("    name = " .. string.format("%q", album.name) .. ",\n")
            file:write("    songs = {\n")
            for _, song in ipairs(album.songs) do
                file:write("      " .. string.format("%q", song) .. ",\n")
            end
            file:write("    },\n")
            file:write("    is_default = " .. tostring(album.is_default) .. ",\n")
            file:write("    created = " .. tostring(album.created) .. "\n")
            file:write("  },\n")
        end
        file:write("}\n")
        self.plugin_state.has_unsaved_changes = false
        file:close()
        return nil
    end

    function Albome:create(name)
        if not name or name == "" then
            return false, "Album name cannot be empty"
        end

        for _, album in ipairs(self.plugin_state.albums) do
            if album.name:lower() == name:lower() then
                return false, "Album already exists"
            end
        end

        table.insert(self.plugin_state.albums, {
            name = name,
            songs = {},
            is_default = false,
            -- TODO: use os.date() for more readable format
            created = os.time()
        })

        self.plugin_state.has_unsaved_changes = true
        return true, "Album '" .. name .. "' created"
    end

    function Albome:add_multiple_songs_by_albome_name(album_name, song_paths)
        local exists = false
        local album = album_name
        for _, albome_name in ipairs(self.plugin_state.albums) do
            if albome_name.name == album_name then
                album = albome_name
                exists = true
            end
        end

        if not exists then
            return false, "albome not exists"
        end
        local added_count = 0
        local skipped_count = 0

        for _, song_path in ipairs(song_paths) do
            local already_exists = false
            for _, existing_song in ipairs(album.songs) do
                if existing_song == song_path then
                    already_exists = true
                    break
                end
            end

            if not already_exists then
                table.insert(album.songs, song_path)
                added_count = added_count + 1
            else
                skipped_count = skipped_count + 1
            end
        end

        if added_count > 0 then
            self.plugin_state.has_unsaved_changes = true
        end

        local message = "Added " .. added_count .. " songs to " .. album.name
        if skipped_count > 0 then
            message = message .. " (" .. skipped_count .. " already existed)"
        end

        return true, message
    end

    function Albome:add_song_by_albome_name(album_name, song_path)
        local exists = false
        local album = nil
        for _, albome_name in ipairs(self.plugin_state.albums) do
            if albome_name.name == album_name then
                album = albome_name
                exists = true
            end
        end

        if not exists then
            return false, "albome not exists"
        end

        -- Check if song already exists in album
        for _, existing_song in ipairs(album.songs) do
            if existing_song == song_path then
                return false, "Song already in " .. album.name
            end
        end

        table.insert(album.songs, song_path)
        self.plugin_state.has_unsaved_changes = true
        return true, "Added to " .. album.name
    end

    function Albome:add_song(album_index, song_path)
        if album_index < 1 or album_index > #self.plugin_state.albums then
            return false, "Invalid album"
        end

        local album = self.plugin_state.albums[album_index]

        -- Check if song already exists in album
        for _, existing_song in ipairs(album.songs) do
            if existing_song == song_path then
                return false, "Song already in " .. album.name
            end
        end

        table.insert(album.songs, song_path)
        self.plugin_state.has_unsaved_changes = true
        return true, "Added to " .. album.name
    end

    function Albome:add_multiple_songs(album_index, song_paths)
        if album_index < 1 or album_index > #self.plugin_state.albums then
            return false, "Invalid album"
        end

        local album = self.plugin_state.albums[album_index]
        local added_count = 0
        local skipped_count = 0

        for _, song_path in ipairs(song_paths) do
            local already_exists = false
            for _, existing_song in ipairs(album.songs) do
                if existing_song == song_path then
                    already_exists = true
                    break
                end
            end

            if not already_exists then
                table.insert(album.songs, song_path)
                added_count = added_count + 1
            else
                skipped_count = skipped_count + 1
            end
        end

        if added_count > 0 then
            self.plugin_state.has_unsaved_changes = true
        end

        local message = "Added " .. added_count .. " songs to " .. album.name
        if skipped_count > 0 then
            message = message .. " (" .. skipped_count .. " already existed)"
        end

        return true, message
    end

    function Albome:remove_song(album_index, song_index)
        if album_index < 1 or album_index > #self.plugin_state.albums then
            return false, "Invalid album"
        end

        local album = self.plugin_state.albums[album_index]
        if song_index < 1 or song_index > #album.songs then
            return false, "Invalid song index"
        end

        local song_name = album.songs[song_index]:match("([^/\\]+)$") or album.songs[song_index]
        table.remove(album.songs, song_index)

        self.plugin_state.has_unsaved_changes = true
        return true, "Removed '" .. song_name .. "' from " .. album.name
    end

    function Albome:delete(album_index)
        if album_index < 1 or album_index > #self.plugin_state.albums then
            return false, "Invalid album"
        end

        local album = self.plugin_state.albums[album_index]
        if album.is_default then
            return false, "Cannot delete default album"
        end

        table.remove(self.plugin_state.albums, album_index)
        if self.plugin_state.current_album_index > #self.plugin_state.albums then
            self.plugin_state.current_album_index = math.max(1, #self.plugin_state.albums)
        end

        self.plugin_state.has_unsaved_changes = true
        return true, "Album '" .. album.name .. "' deleted"
    end
end

return Albome
