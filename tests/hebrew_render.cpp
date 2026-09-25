/*
 Bible Viewer - Scripture, At Your Fingertips.
 Copyright (C) 2026  Jacob T. Ward

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

// Standalone headless renderer test; includes implementation to inspect shaping.
#include "../src/translate.cpp"
#include <cassert>
#include <iostream>

int main()
{
  for (int context = 0; context < 2; ++context)
  {
    ImGui::CreateContext();
    auto &io = ImGui::GetIO();
    io.IniFilename = nullptr;
    io.DisplaySize = ImVec2(800, 600);
    io.DeltaTime = 1.0f / 60.0f;
    io.BackendFlags |= ImGuiBackendFlags_RendererHasTextures;
    io.Fonts->AddFontDefault();
    size_t cached = 0;
    for (int frame = 0; frame < 3; ++frame)
    {
      ImGui::NewFrame();
      ImGui::SetNextWindowPos(ImVec2(0, 0));
      ImGui::SetNextWindowSize(ImVec2(800, 600));
      ImGui::Begin("Hebrew test");
      auto &renderer = hebrewRenderer();
      float width = 0;
      auto shaped = shapeHebrewLine(renderer, u8"אבג", width);
      assert(shaped.size() == 3 && width > 0);
      assert(shaped[0].id == FT_Get_Char_Index(renderer.face, 0x05D2));
      assert(shaped[2].id == FT_Get_Char_Index(renderer.face, 0x05D0));
      width = 0;
      shaped = shapeHebrewLine(renderer, u8"אב 123", width);
      assert(shaped[0].id == FT_Get_Char_Index(renderer.face, '1'));
      assert(shaped[1].id == FT_Get_Char_Index(renderer.face, '2'));
      assert(shaped[2].id == FT_Get_Char_Index(renderer.face, '3'));
      width = 0;
      shaped = shapeHebrewLine(renderer, u8"שָׁלוֹם", width);
      for (const auto &g : shaped)
      {
        assert(g.id != 0);
      }
      float plainWidth = 0;
      const auto plain = shapeHebrewLine(renderer, u8"שלום", plainWidth);
      assert(shaped.size() > plain.size());
      // Vowel marks must not consume additional horizontal advance.
      assert(std::abs(width - plainWidth) < 0.1f);
      TextHebrew(decodeEntities("&#1488;&#1463;&#1489;&#1456;&#1513;&#1464;&#1473;&#1500;&#1493;&#1465;&#1501;"));
      TextHebrew(u8"שָׁלוֹם (John 3:16)\nאב 123");
      TextHebrew("");
      if (frame) assert(renderer.glyphs.size() == cached);
      cached = renderer.glyphs.size();
      ImGui::End();
      ImGui::Render();
      assert(ImGui::GetDrawData()->TotalVtxCount > 0);
      // Simulate the backend acknowledging texture uploads.
      for (auto *texture : ImGui::GetPlatformIO().Textures)
      {
        if (texture->Status == ImTextureStatus_WantCreate)
          texture->SetTexID(1);
        if (texture->Status != ImTextureStatus_WantDestroy)
          texture->SetStatus(ImTextureStatus_OK);
      }
    }
    ImGui::DestroyContext();
  }
  std::cout << "Hebrew shaping, draw output, cache reuse, and context cleanup passed\n";
}
