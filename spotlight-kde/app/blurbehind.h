#pragma once
#include <QPointer>
#include <QQuickItem>
#include <QWindow>

// Asks KWin to blur behind this item's rounded rectangle.
class BlurBehind : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(qreal radius MEMBER m_radius NOTIFY changed)
    Q_PROPERTY(bool active MEMBER m_active NOTIFY changed)
public:
    explicit BlurBehind(QQuickItem *parent = nullptr);
    ~BlurBehind() override;
Q_SIGNALS:
    void changed();

protected:
    void itemChange(ItemChange change, const ItemChangeData &data) override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    void apply();
    qreal m_radius = 0;
    bool m_active = true;
    QPointer<QWindow> m_window;
};
