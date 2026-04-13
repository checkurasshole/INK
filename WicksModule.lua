local WicksModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LINK = "https://wickshop-sparkle.lovable.app/"

local T = {
	en    = {title="Wicks Shop",status="Access Status:",paid="Paid",purchase="Purchase at",copy="Copy",copied="Copied!",plan="Plan",premium="Premium",keytype="Key Type",monthly="Monthly",lifetime="Lifetime",executor="Executor",universal="Universal",visit="Visit Shop",lang="English"},
	fr    = {title="Wicks Shop",status="Statut d'accès :",paid="Payé",purchase="Acheter ici",copy="Copier",copied="Copié !",plan="Plan",premium="Premium",keytype="Type de clé",monthly="Mensuel",lifetime="À vie",executor="Exécuteur",universal="Universel",visit="Visiter la boutique",lang="Français"},
	th    = {title="Wicks Shop",status="สถานะการเข้าถึง:",paid="ชำระแล้ว",purchase="ซื้อได้ที่",copy="คัดลอก",copied="คัดลอกแล้ว!",plan="แผน",premium="พรีเมียม",keytype="ประเภทคีย์",monthly="รายเดือน",lifetime="ตลอดชีพ",executor="ตัวรัน",universal="สากล",visit="เยี่ยมชมร้านค้า",lang="ภาษาไทย"},
	ko    = {title="Wicks Shop",status="액세스 상태:",paid="결제됨",purchase="구매처",copy="복사",copied="복사됨!",plan="플랜",premium="프리미엄",keytype="키 유형",monthly="월간",lifetime="평생",executor="실행기",universal="범용",visit="상점 방문",lang="한국어"},
	zhCN  = {title="Wicks Shop",status="访问状态：",paid="已付款",purchase="购买地址",copy="复制",copied="已复制！",plan="计划",premium="高级版",keytype="密钥类型",monthly="月度",lifetime="终身",executor="执行器",universal="通用",visit="访问商店",lang="简体中文"},
	de    = {title="Wicks Shop",status="Zugriffsstatus:",paid="Bezahlt",purchase="Kaufen bei",copy="Kopieren",copied="Kopiert!",plan="Plan",premium="Premium",keytype="Schlüsseltyp",monthly="Monatlich",lifetime="Lebenslang",executor="Ausführer",universal="Universell",visit="Shop besuchen",lang="Deutsch"},
	ru    = {title="Wicks Shop",status="Статус доступа:",paid="Оплачено",purchase="Купить по адресу",copy="Копировать",copied="Скопировано!",plan="Тариф",premium="Премиум",keytype="Тип ключа",monthly="Ежемесячный",lifetime="Пожизненный",executor="Исполнитель",universal="Универсальный",visit="Посетить магазин",lang="Русский"},
	id    = {title="Wicks Shop",status="Status Akses:",paid="Berbayar",purchase="Beli di",copy="Salin",copied="Disalin!",plan="Paket",premium="Premium",keytype="Tipe Kunci",monthly="Bulanan",lifetime="Seumur Hidup",executor="Eksekutor",universal="Universal",visit="Kunjungi Toko",lang="Indonesia"},
	pt    = {title="Wicks Shop",status="Status de Acesso:",paid="Pago",purchase="Comprar em",copy="Copiar",copied="Copiado!",plan="Plano",premium="Premium",keytype="Tipo de Chave",monthly="Mensal",lifetime="Vitalício",executor="Executor",universal="Universal",visit="Visitar Loja",lang="Português"},
	fil   = {title="Wicks Shop",status="Status ng Access:",paid="Nabayaran",purchase="Bilhin sa",copy="Kopyahin",copied="Nakopya!",plan="Plano",premium="Premium",keytype="Uri ng Susi",monthly="Buwanan",lifetime="Panghabambuhay",executor="Tagapaganap",universal="Universal",visit="Bisitahin ang Tindahan",lang="Filipino"},
	es    = {title="Wicks Shop",status="Estado de acceso:",paid="Pagado",purchase="Comprar en",copy="Copiar",copied="¡Copiado!",plan="Plan",premium="Premium",keytype="Tipo de clave",monthly="Mensual",lifetime="De por vida",executor="Ejecutor",universal="Universal",visit="Visitar Tienda",lang="Español"},
	vi    = {title="Wicks Shop",status="Trạng thái:",paid="Đã thanh toán",purchase="Mua tại",copy="Sao chép",copied="Đã sao chép!",plan="Gói",premium="Cao cấp",keytype="Loại khóa",monthly="Hàng tháng",lifetime="Trọn đời",executor="Trình thực thi",universal="Phổ thông",visit="Truy cập Cửa hàng",lang="Tiếng Việt"},
}

local LANG_ORDER = {"en","fr","th","ko","zhCN","de","ru","id","pt","fil","es","vi"}

function WicksModule.Load()
	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	local currentLang = "en"
	local currentKeyType = "monthly"
	local keyDropOpen = false
	local langDropOpen = false

	local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
	local function corner(p,r) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r) end

	local function mkFrame(parent,props)
		local f=Instance.new("Frame",parent) f.BorderSizePixel=0
		for k,v in pairs(props) do f[k]=v end return f
	end
	local function mkLabel(parent,props)
		local l=Instance.new("TextLabel",parent) l.BackgroundTransparency=1
		for k,v in pairs(props) do l[k]=v end return l
	end
	local function mkBtn(parent,props)
		local b=Instance.new("TextButton",parent) b.BorderSizePixel=0
		for k,v in pairs(props) do b[k]=v end return b
	end

	local ScreenGui = Instance.new("ScreenGui",PlayerGui)
	ScreenGui.Name="WicksShopGui" ScreenGui.ResetOnSpawn=false
	ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling ScreenGui.DisplayOrder=10

	local Main = mkFrame(ScreenGui,{
		Size=UDim2.new(0,290,0,276),
		Position=UDim2.new(0.5,-145,0.5,-138),
		BackgroundColor3=rgb(24,24,24),
		Active=true, Draggable=true, ZIndex=2,
	})
	corner(Main,12)

	local RainbowStroke = Instance.new("UIStroke",Main)
	RainbowStroke.Thickness=2
	RainbowStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

	local RainbowGrad = Instance.new("UIGradient",RainbowStroke)
	RainbowGrad.Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,   rgb(255,110,199)),
		ColorSequenceKeypoint.new(0.2, rgb(255,215,0)),
		ColorSequenceKeypoint.new(0.4, rgb(0,229,255)),
		ColorSequenceKeypoint.new(0.6, rgb(123,97,255)),
		ColorSequenceKeypoint.new(0.8, rgb(255,110,199)),
		ColorSequenceKeypoint.new(1,   rgb(0,229,255)),
	})

	local TitleBar = mkFrame(Main,{Size=UDim2.new(1,0,0,38),BackgroundColor3=rgb(14,14,14),ZIndex=3})
	corner(TitleBar,12)
	mkFrame(TitleBar,{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=rgb(14,14,14),ZIndex=3})

	local TitleLbl = mkLabel(TitleBar,{Size=UDim2.new(1,-40,1,0),Position=UDim2.new(0,13,0,0),Text="Wicks Shop",TextColor3=rgb(200,200,200),TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4})

	local CloseBtn = mkBtn(TitleBar,{Size=UDim2.new(0,20,0,20),Position=UDim2.new(1,-28,0.5,-10),BackgroundColor3=rgb(226,75,74),Text="✕",TextColor3=rgb(255,255,255),TextSize=11,Font=Enum.Font.GothamBold,ZIndex=4})
	corner(CloseBtn,10)

	local Body = mkFrame(Main,{Size=UDim2.new(1,-28,0,218),Position=UDim2.new(0,14,0,44),BackgroundTransparency=1,ZIndex=3})

	local StatusDot = mkFrame(Body,{Size=UDim2.new(0,8,0,8),Position=UDim2.new(0,0,0,5),BackgroundColor3=rgb(29,158,117),ZIndex=4})
	corner(StatusDot,9)

	local StatusLbl = mkLabel(Body,{Size=UDim2.new(0,115,0,18),Position=UDim2.new(0,16,0,0),Text="Access Status:",TextColor3=rgb(220,220,220),TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4})

	local PaidBadge = mkLabel(Body,{Size=UDim2.new(0,52,0,18),Position=UDim2.new(1,-52,0,0),BackgroundColor3=rgb(13,46,36),BackgroundTransparency=0,Text="Paid",TextColor3=rgb(77,212,160),TextSize=11,Font=Enum.Font.GothamBold,ZIndex=4})
	corner(PaidBadge,9)
	local ps=Instance.new("UIStroke",PaidBadge) ps.Color=rgb(29,158,117) ps.Thickness=1

	local PurchaseLbl = mkLabel(Body,{Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,0,24),Text="PURCHASE AT",TextColor3=rgb(75,75,75),TextSize=10,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4})

	local LinkBox = mkLabel(Body,{Size=UDim2.new(1,-62,0,26),Position=UDim2.new(0,0,0,39),BackgroundColor3=rgb(14,14,14),BackgroundTransparency=0,Text="wickshop-sparkle.lovable.app",TextColor3=rgb(100,100,100),TextSize=11,Font=Enum.Font.Gotham,ClipsDescendants=true,ZIndex=4})
	corner(LinkBox,7)

	local CopyBtn = mkBtn(Body,{Size=UDim2.new(0,54,0,26),Position=UDim2.new(1,-54,0,39),BackgroundColor3=rgb(36,36,36),Text="Copy",TextColor3=rgb(210,210,210),TextSize=11,Font=Enum.Font.GothamBold,ZIndex=4})
	corner(CopyBtn,7)

	mkFrame(Body,{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,77),BackgroundColor3=rgb(40,40,40),ZIndex=4})

	local function makeRow(yPos,keyTxt,valTxt)
		local k=mkLabel(Body,{Size=UDim2.new(0.5,0,0,18),Position=UDim2.new(0,0,0,yPos),Text=keyTxt,TextColor3=rgb(80,80,80),TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4})
		local v=mkLabel(Body,{Size=UDim2.new(0.5,0,0,18),Position=UDim2.new(0.5,0,0,yPos),Text=valTxt,TextColor3=rgb(210,210,210),TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=4})
		return k,v
	end

	local PlanKey,PlanVal   = makeRow(84,"Plan","Premium")
	local KeyTypeKey,_      = makeRow(106,"Key Type","")
	local ExecKey,ExecVal   = makeRow(128,"Executor","Universal")
	local LangKey,_         = makeRow(150,"Language","")

	local function mkDropBtn(yPos,width,text)
		local b=mkBtn(Body,{Size=UDim2.new(0,width,0,20),Position=UDim2.new(1,-width,0,yPos),BackgroundColor3=rgb(36,36,36),Text=text.." v",TextColor3=rgb(210,210,210),TextSize=11,Font=Enum.Font.GothamBold,ZIndex=4})
		corner(b,5) return b
	end

	local KeyTypeBtn = mkDropBtn(104,92,"Monthly")
	local LangBtn    = mkDropBtn(148,100,"English")

	local function mkDropFrame(yOff,w,h)
		local f=mkFrame(Main,{Size=UDim2.new(0,w,0,h),Position=UDim2.new(1,-(w+16),0,yOff),BackgroundColor3=rgb(30,30,30),Visible=false,ZIndex=8,ClipsDescendants=true})
		corner(f,8)
		local s=Instance.new("UIStroke",f) s.Color=rgb(50,50,50) s.Thickness=1
		return f
	end

	local KeyDrop  = mkDropFrame(162,95,44)
	local LangDrop = mkDropFrame(186,130,22*12+4)

	local function mkDropItem(parent,text,yPos,code)
		local b=mkBtn(parent,{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,yPos),BackgroundColor3=rgb(30,30,30),BackgroundTransparency=0,Text=text,TextColor3=rgb(200,200,200),TextSize=11,Font=Enum.Font.Gotham,ZIndex=9})
		if code then b.Name=code end
		b.MouseEnter:Connect(function() b.BackgroundColor3=rgb(45,45,45) end)
		b.MouseLeave:Connect(function() b.BackgroundColor3=rgb(30,30,30) end)
		return b
	end

	local MonthlyItem  = mkDropItem(KeyDrop,"Monthly",0,"monthly")
	local LifetimeItem = mkDropItem(KeyDrop,"Lifetime",22,"lifetime")

	local langItems = {}
	for i,code in ipairs(LANG_ORDER) do
		langItems[code] = mkDropItem(LangDrop,T[code].lang,(i-1)*22,code)
	end

	local VisitBtn = mkBtn(Body,{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,174),BackgroundColor3=rgb(13,46,36),Text="Visit Shop",TextColor3=rgb(77,212,160),TextSize=12,Font=Enum.Font.GothamBold,ZIndex=4})
	corner(VisitBtn,8)
	local vs=Instance.new("UIStroke",VisitBtn) vs.Color=rgb(29,158,117) vs.Thickness=1

	local function closeDrops()
		KeyDrop.Visible=false LangDrop.Visible=false
		keyDropOpen=false langDropOpen=false
	end

	local function applyLang()
		local t=T[currentLang]
		TitleLbl.Text=t.title StatusLbl.Text=t.status PaidBadge.Text=t.paid
		PurchaseLbl.Text="PURCHASE AT" PlanKey.Text=t.plan PlanVal.Text=t.premium
		KeyTypeKey.Text=t.keytype KeyTypeBtn.Text=(currentKeyType=="monthly" and t.monthly or t.lifetime).." v"
		MonthlyItem.Text=t.monthly LifetimeItem.Text=t.lifetime
		ExecKey.Text=t.executor ExecVal.Text=t.universal
		LangKey.Text=t.lang LangBtn.Text=t.lang.." v"
		VisitBtn.Text=t.visit CopyBtn.Text=t.copy
	end

	KeyTypeBtn.MouseButton1Click:Connect(function()
		keyDropOpen=not keyDropOpen LangDrop.Visible=false langDropOpen=false KeyDrop.Visible=keyDropOpen
	end)
	LangBtn.MouseButton1Click:Connect(function()
		langDropOpen=not langDropOpen KeyDrop.Visible=false keyDropOpen=false LangDrop.Visible=langDropOpen
	end)
	MonthlyItem.MouseButton1Click:Connect(function() currentKeyType="monthly" closeDrops() applyLang() end)
	LifetimeItem.MouseButton1Click:Connect(function() currentKeyType="lifetime" closeDrops() applyLang() end)
	for code,item in pairs(langItems) do
		item.MouseButton1Click:Connect(function() currentLang=code closeDrops() applyLang() end)
	end

	CopyBtn.MouseButton1Click:Connect(function()
		local t=T[currentLang]
		setclipboard(LINK)
		CopyBtn.Text=t.copied CopyBtn.TextColor3=rgb(77,212,160)
		task.wait(1.5) CopyBtn.Text=t.copy CopyBtn.TextColor3=rgb(210,210,210)
	end)
	CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
	VisitBtn.MouseButton1Click:Connect(function()
		if syn and syn.open_url then syn.open_url(LINK) end
	end)

	local angle = 0
	RunService.RenderStepped:Connect(function(dt)
		angle=(angle+dt*60)%360
		RainbowGrad.Rotation=angle
	end)

	applyLang()
end

return WicksModule