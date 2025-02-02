import matplotlib.pyplot as plt

voltaje = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
corriente = [2.22, 7.07, 12, 17, 21.9, 26.9, 31.9, 36.9, 41.8, 46.8]

plt.scatter(voltaje, corriente)
plt.xlabel('Voltaje (V)')
plt.ylabel('Corriente (mA)')
plt.title('Curva Voltaje vs Corriente')
plt.show()