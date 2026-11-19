#include "blurbehind.h"
#include <KWindowEffects>
#include <QPainterPath>
#include <QQuickWindow>
#include <QRegion>

BlurBehind::BlurBehind(QQuickItem *parent)
    : QQuickItem(parent)
{
    connect(this, &BlurBehind::changed, this, &BlurBehind::apply);
    connect(this, &QQuickItem::visibleChanged, this, &BlurBehind::apply);
    connect(this, &QQuickItem::xChanged, this, &BlurBehind::apply);
    connect(this, &QQuickItem::yChanged, this, &BlurBehind::apply);
}

BlurBehind::~BlurBehind()
{
    if (m_window)
        KWindowEffects::enableBlurBehind(m_window, false);
}

void BlurBehind::itemChange(ItemChange change, const ItemChangeData &data)
{
    if (change == ItemSceneChange) {
        if (m_window) {
            disconnect(m_window, nullptr, this, nullptr);
            KWindowEffects::enableBlurBehind(m_window, false);
        }
        m_window = data.window;
        if (m_window)
            connect(m_window, &QWindow::visibleChanged, this, &BlurBehind::apply);
    }
    QQuickItem::itemChange(change, data);
    apply();
}

void BlurBehind::geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    apply();
}

void BlurBehind::apply()
{
    if (!m_window || !m_window->isVisible())
        return;
    const QRectF r = mapRectToScene(QRectF(0, 0, width(), height()));
    if (!m_active || !isVisible() || r.isEmpty()) {
        KWindowEffects::enableBlurBehind(m_window, false);
        return;
    }
    QPainterPath path;
    path.addRoundedRect(r, m_radius, m_radius);
    KWindowEffects::enableBlurBehind(m_window, true, QRegion(path.toFillPolygon().toPolygon()));
}
